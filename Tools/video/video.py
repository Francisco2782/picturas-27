"""PictuRAS video microservice (RabbitMQ worker).

Receives the video and the whole effect pipeline in a single message,
processes it with video_processor and replies to the projects orchestrator on
project_queue. Progress updates are also published to project_queue for the
projects orchestrator to persist and forward to ws_queue.

Unlike the image tools, the message is only acknowledged after the job ends:
if the worker dies midway, RabbitMQ redelivers it.
"""
import datetime
import json
import os
import signal
import time
import uuid

import pika
import pytz
from pika.exchange_type import ExchangeType

import utils.env as env
from effects import UnsupportedEffect
from progress import build_progress_message
from video_processor import InvalidSpeed, InvalidTrim, InvalidVideo, process_video

EXCHANGE = "picturas"
VIDEO_QUEUE = "video_queue"
PROJECT_QUEUE = "project_queue"
WS_QUEUE = "ws_queue"
MICROSERVICE = "picturas-video-tool-ms"

CODES = {
    "wrong_procedure": 2000,
    "error_processing": 2001,
    "unsupported_effect": 2002,
    "invalid_trim": 2003,
    "invalid_video": 2004,
    "invalid_speed": 2005,
}


def now():
    return datetime.datetime.now(pytz.utc)


class VideoWorker:
    def __init__(self):
        self._draining = False
        signal.signal(signal.SIGUSR1, self._request_drain)
        self._connection = self._connect()
        self._channel = self._connection.channel()
        self._channel.exchange_declare(exchange=EXCHANGE,
                                       exchange_type=ExchangeType.direct, durable=True)
        self._channel.queue_declare(queue=VIDEO_QUEUE, durable=True)
        self._channel.queue_bind(queue=VIDEO_QUEUE, exchange=EXCHANGE, routing_key=VIDEO_QUEUE)
        # one video at a time per replica; parallelism comes from replicas
        self._channel.basic_qos(prefetch_count=1)
        self._result_channel = self._connection.channel()
        self._result_channel.confirm_delivery()

    def _request_drain(self, _signal, _frame):
        # Signal handlers must not call Pika while it is dispatching or publishing.
        self._draining = True

    @staticmethod
    def _connect():
        credentials = pika.PlainCredentials(env.RABBITMQ_USERNAME, env.RABBITMQ_PASSWORD)
        params = pika.ConnectionParameters(
            env.RABBITMQ_HOST, int(env.RABBITMQ_PORT), "/", credentials,
            # processing a video blocks this thread for minutes; without a
            # heartbeat the broker does not drop the connection midway
            heartbeat=0,
        )
        for attempt in range(30):
            try:
                return pika.BlockingConnection(params)
            except pika.exceptions.AMQPConnectionError:
                time.sleep(2)
        raise RuntimeError("Could not connect to RabbitMQ")

    def _publish(self, queue, msg):
        self._channel.basic_publish(exchange=EXCHANGE, routing_key=queue,
                                    body=json.dumps(msg))

    def _publish_result(self, msg):
        self._result_channel.basic_publish(
            exchange=EXCHANGE, routing_key=PROJECT_QUEUE, body=json.dumps(msg),
            properties=pika.BasicProperties(delivery_mode=2), mandatory=True,
        )

    def _reply_success(self, msg_id, started, output_uri, video_info):
        output = {"type": video_info.get("output_type", "video"),
                  "imageURI": video_info.get("output_path", output_uri)}
        if output["type"] == "frames":
            output["frames"] = video_info["frames"]
        self._publish_result({
            "messageId": f"video-{uuid.uuid4()}",
            "correlationId": msg_id,
            "timestamp": now().isoformat(),
            "status": "success",
            "output": output,
            "metadata": {
                "processingTime": (now() - started).total_seconds() * 1000,
                "microservice": MICROSERVICE,
                "video": video_info,
            },
        })

    def _reply_error(self, msg_id, started, code, message, input_uri):
        self._publish_result({
            "messageId": f"video-{uuid.uuid4()}",
            "correlationId": msg_id,
            "timestamp": now().isoformat(),
            "status": "error",
            "error": {
                "code": code,
                "message": message,
                "msg": message,  # the orchestrator reads error.msg
                "details": {"inputFileURI": input_uri},
            },
            "metadata": {
                "processingTime": (now() - started).total_seconds() * 1000,
                "microservice": MICROSERVICE,
            },
        })

    def _progress(self, progress, preview, percent):
        message = build_progress_message(progress, preview, percent, now().isoformat())
        if not message:
            return
        self._publish(PROJECT_QUEUE, message)

    def callback(self, ch, method, properties, body):
        started = now()
        info = {}
        try:
            info = json.loads(body.decode())
            msg_id = info["messageId"]
            params = info["parameters"]
            input_uri = params["inputImageURI"]
            output_uri = params["outputImageURI"]
            tools = params.get("tools") or []
            preview = bool(params.get("preview"))
            progress = params.get("progress") or {}
        except (ValueError, KeyError) as e:
            print(f"[video] invalid message discarded: {e}", flush=True)
            ch.basic_ack(delivery_tag=method.delivery_tag)
            return

        print(f"[video] msg={msg_id} preview={preview} tools={[t.get('procedure') for t in tools]}",
              flush=True)

        if info.get("procedure") != "video":
            self._reply_error(msg_id, started, CODES["wrong_procedure"],
                              "The procedure received does not fit into this tool", input_uri)
        else:
            try:
                result = process_video(
                    input_uri, output_uri, tools, preview=preview,
                    progress_cb=lambda pct: self._progress(progress, preview, pct),
                )
                self._reply_success(msg_id, started, output_uri, result)
                print(f"[video] msg={msg_id} ok frames={result['frames']} "
                      f"t={(now() - started).total_seconds():.1f}s", flush=True)
            except UnsupportedEffect as e:
                self._reply_error(msg_id, started, CODES["unsupported_effect"], str(e), input_uri)
            except InvalidTrim as e:
                self._reply_error(msg_id, started, CODES["invalid_trim"], str(e), input_uri)
            except InvalidSpeed as e:
                self._reply_error(msg_id, started, CODES["invalid_speed"], str(e), input_uri)
            except InvalidVideo as e:
                self._reply_error(msg_id, started, CODES["invalid_video"], str(e), input_uri)
            except pika.exceptions.AMQPError:
                # Closing the failed connection leaves the delivery for the broker to retry.
                raise
            except Exception as e:  # noqa: BLE001 - any other failure is reported
                self._reply_error(msg_id, started, CODES["error_processing"], str(e), input_uri)

        # manual ack only at the end
        ch.basic_ack(delivery_tag=method.delivery_tag)

    def run(self):
        deliveries = self._channel.consume(VIDEO_QUEUE, inactivity_timeout=0.5)
        try:
            while not self._draining:
                method, properties, body = next(deliveries)
                if method is not None and not self._draining:
                    self.callback(self._channel, method, properties, body)
        finally:
            if self._connection.is_open:
                self._connection.close()
        print("[video] drained and stopped", flush=True)


if __name__ == "__main__":
    VideoWorker().run()

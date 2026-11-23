const { send_rabbit_msg, read_rabbit_msg } = require('./rabbit_mq')
const amqp = require('amqplib');
const { v4: uuidv4 } = require('uuid');

const queues = {
    'cut': 'cut_queue',
    'scale': 'scale_queue',
    'border': 'border_queue',
    'saturation': 'saturation_queue',
    'brightness': 'brightness_queue',
    'contrast': 'contrast_queue',
    'binarization': 'binarization_queue',
    'resize': 'resize_queue',
    'rotate': 'rotate_queue',
    'cut_ai': 'cut_ai_queue',
    'upgrade_ai': 'upgrade_ai_queue',
    'bg_remove_ai': 'bg_remove_ai_queue',
    'text_ai': 'text_ai_queue',
    'obj_ai': 'obj_ai_queue',
    'people_ai': 'people_ai_queue',
    'expand_ai': 'expand_ai_queue',
    'watermark': 'watermark_queue',
    'video': 'video_queue',
    'project': 'project_queue',
    'ws': 'ws_queue'
}

function send_msg_tool(msg_id, timestamp, og_img_uri, new_img_uri, tool, params) {
    const queue = queues[tool];
    const msg = {
        "messageId": msg_id,
        "timestamp": timestamp,
        "procedure": tool,
        "parameters": {
            "inputImageURI": og_img_uri,
            "outputImageURI": new_img_uri,
            ... params
        }
    };

    return send_rabbit_msgConfirmed(msg, queue);
}

async function send_rabbit_msgConfirmed(msg, queue) {
    const host = process.env.RABBITMQ_HOST;
    const port = process.env.RABBITMQ_PORT;
    const username = process.env.RABBITMQ_USER;
    const password = process.env.RABBITMQ_PASS;
    const connection = await amqp.connect(`amqp://${username}:${password}@${host}:${port}`);
    try {
        const channel = await connection.createConfirmChannel();
        try {
            await channel.assertExchange('picturas', 'direct', { durable: true });
            await new Promise((resolve, reject) => {
                const options = queue === queues.video ? { persistent: true } : {};
                channel.publish('picturas', queue, Buffer.from(JSON.stringify(msg)), options, (error) => {
                    if (error) reject(error);
                    else resolve();
                });
            });
        } finally {
            await channel.close();
        }
    } finally {
        await connection.close();
    }
}

function send_msg_client(msg_id, timestamp, user, run = {}) {
    const queue = queues['ws'];
    const msg = {
        "messageId": msg_id,
        "timestamp": timestamp,
        "user": user,
        "status": 'success',
        ...run,
    };

    send_rabbit_msg(msg, queue);
}

function send_msg_client_error(msg_id, timestamp, user, error_code, error_msg, run = {}) {
    const queue = queues['ws'];
    const msg = {
        "messageId": msg_id,
        "timestamp": timestamp,
        "user": user,
        "status": "error",
        "errorCode": error_code,
        "errorMsg": error_msg,
        ...run,
    };

    send_rabbit_msg(msg, queue);
}

function send_msg_client_preview(msg_id, timestamp, user, url) {
    const queue = queues['ws'];
    const msg = {
        "messageId": msg_id,
        "timestamp": timestamp,
        "status": 'success',
        "user": user,
        "img_url": url
    };

    send_rabbit_msg(msg, queue);
}

function send_msg_client_preview_error(msg_id, timestamp, user, error_code, error_msg) {
    const queue = queues['ws'];
    const msg = {
        "messageId": msg_id,
        "timestamp": timestamp,
        "user": user,
        "status": "error",
        "errorCode": error_code,
        "errorMsg": error_msg
    };

    send_rabbit_msg(msg, queue);
}

function send_msg_client_video_progress({ user, projectId, imgId, preview, percent, timestamp, runToken }) {
    send_rabbit_msg({
        messageId: `update-client-video-progress-${uuidv4()}`,
        timestamp,
        status: 'success',
        user,
        projectId,
        imgId,
        preview,
        percent,
        runToken,
    }, queues['ws']);
}

function read_msg(callback){
    read_rabbit_msg(queues['project'], callback);
}

function send_msg_project_op({ projectId, ownerId, op }) {
  const queue = queues["ws"];
  const msg = {
    type: "project-op",
    projectId,
    ownerId,
    op, // payload da operação 
    timestamp: Date.now(),
    status: "success",
  };
  send_rabbit_msg(msg, queue);
}

module.exports = { send_msg_tool, send_msg_client, send_msg_client_error, send_msg_client_preview, send_msg_client_preview_error, send_msg_client_video_progress, read_msg, send_msg_project_op };

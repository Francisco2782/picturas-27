from argparse import Namespace
from io import StringIO
from unittest.mock import Mock

from scripts import autoscale_video


def test_scaling_respects_busy_workers_idle_period_cooldown_and_bounds(monkeypatch):
    args = Namespace(project="picturas", rabbit_user="user", rabbit_password="test",
                     rabbit_url="http://localhost/queue", minimum=1, maximum=2,
                     cooldown=5, idle_seconds=10)
    scaler = autoscale_video.Autoscaler(args)
    queue = {"messages_ready": 1, "messages_unacknowledged": 1, "consumers": 1}
    monkeypatch.setattr(autoscale_video, "urlopen", lambda *args, **kwargs: StringIO())
    monkeypatch.setattr(autoscale_video.json, "load", lambda response: queue)
    docker = Mock()
    monkeypatch.setattr(autoscale_video, "docker", docker)
    clock = Mock(return_value=0)
    monkeypatch.setattr(autoscale_video.time, "monotonic", clock)

    def worker(replica, *, running=True):
        return {"Id": str(replica), "Name": f"worker-{replica}",
                "State": {"Running": running, "Restarting": False,
                          "Status": "running" if running else "exited"}}

    scaler.workers = Mock(return_value=[worker(1)])
    scaler.step()
    assert docker.call_args.args[-2:] == ("video_tool=2", "video_tool")
    docker.reset_mock()
    clock.return_value = 1
    scaler.step()
    docker.assert_not_called()

    scaler.workers.return_value = [worker(1), worker(2)]
    queue["consumers"] = 2
    clock.return_value = 10
    scaler.step()
    docker.assert_not_called()

    queue["messages_ready"] = 0
    clock.return_value = 30
    scaler.step()
    assert scaler.empty_since is None
    docker.assert_not_called()

    queue["messages_unacknowledged"] = 0
    clock.return_value = 31
    scaler.step()
    clock.return_value = 40
    scaler.step()
    docker.assert_not_called()
    clock.return_value = 41
    scaler.step()
    docker.assert_called_once_with("kill", "--signal=USR1", "2")

    docker.reset_mock()
    queue["consumers"] = 1
    scaler.workers.return_value = [worker(1), worker(2, running=False)]
    clock.return_value = 42
    scaler.step()
    clock.return_value = 55
    scaler.step()
    docker.assert_not_called()
    queue["messages_ready"] = 1
    scaler.step()
    docker.assert_called_once_with("start", "2")

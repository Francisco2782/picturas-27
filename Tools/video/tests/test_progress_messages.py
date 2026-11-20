from progress import build_progress_message


def test_progress_payload_has_source_run_and_video_identifiers():
    message = build_progress_message({
        "sourceProcessId": "request-123",
        "projectId": "project-1",
        "imgId": "video-1",
        "runToken": 7,
    }, preview=True, percent=42, timestamp="2026-11-20T10:00:00+00:00")

    assert message["messageType"] == "video-progress"
    assert message["messageId"].startswith("video-progress-")
    assert message["sourceProcessId"] == "request-123"
    assert message["projectId"] == "project-1"
    assert message["mediaId"] == "video-1"
    assert message["runToken"] == 7
    assert message["percent"] == 42
    assert message["preview"] is True
    assert message["timestamp"] == "2026-11-20T10:00:00+00:00"


def test_progress_without_a_source_process_is_not_published():
    assert build_progress_message(
        {"projectId": "project-1", "imgId": "video-1"},
        preview=False,
        percent=10,
        timestamp="2026-11-20T10:00:00+00:00",
    ) is None

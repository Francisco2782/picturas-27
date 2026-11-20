import uuid


def build_progress_message(progress, preview, percent, timestamp):
    if not progress or not progress.get("sourceProcessId"):
        return None
    return {
        "messageType": "video-progress",
        "messageId": f"video-progress-{uuid.uuid4()}",
        "sourceProcessId": progress["sourceProcessId"],
        "projectId": progress.get("projectId"),
        "mediaId": progress.get("imgId"),
        "runToken": progress.get("runToken"),
        "preview": bool(preview),
        "percent": percent,
        "timestamp": timestamp,
    }

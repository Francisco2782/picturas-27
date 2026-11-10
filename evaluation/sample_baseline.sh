#!/usr/bin/env bash
OUT=${1:-baseline.csv}
echo "ts,ready,unacked,cpu,mem" > "$OUT"
while true; do
  Q=$(curl -s -u user:password "http://localhost:15672/api/queues/%2F/video_queue")
  READY=$(echo "$Q" | python3 -c "import sys,json;print(json.load(sys.stdin).get('messages_ready',''))")
  UNACK=$(echo "$Q" | python3 -c "import sys,json;print(json.load(sys.stdin).get('messages_unacknowledged',''))")
  S=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" picturas-video_tool-1 | sed 's/ \/ [^,]*//')
  echo "$(date +%s),$READY,$UNACK,$S" >> "$OUT"
  sleep 1
done

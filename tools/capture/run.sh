#!/usr/bin/env bash
# GIF용 영상 캡처. 사용: GODOT=... bash tools/capture/run.sh <절대경로/출력.avi> right|up|down|diag|turn
# 개발용 창 축소(360x640) 설정을 임시 override.cfg로 풀어 720x1280으로 찍는다.
set -euo pipefail
out=$1; shift  # 절대 경로로 줄 것
printf '[display]\nwindow/size/window_width_override=0\nwindow/size/window_height_override=0\n' > override.cfg
trap 'rm -f override.cfg' EXIT
"${GODOT:-godot}" --path . --resolution 720x1280 --write-movie "$out" --fixed-fps 60 res://tools/capture/capture.tscn -- "$@"

#!/bin/bash
# Records the full seeded autopilot run with Godot Movie Maker (MJPEG AVI).
cd "$(dirname "$0")/.."
G=${GODOT:-godot}   # path to a Godot 4.7.2 binary
OUT=build/recording
mkdir -p $OUT; rm -f $OUT/full.avi $OUT/record.done
timeout 1200 xvfb-run -a -s "-screen 0 1280x720x24" $G --path . --rendering-driver opengl3 --write-movie $OUT/full.avi --fixed-fps 30 --quit-after 18000 -- --autopilot --quit-at-end > $OUT/record.log 2>&1
echo DONE > $OUT/record.done

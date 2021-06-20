#!/bin/bash
#
# Convert a video to h264 format. Requires ffmpeg.
# Note that Safari only very recently supports VP8/webm.
#
# To run in a batch, try:
#
# find . -iname "*.webm" -exec ./vid_to_264.sh {} {}.mp4 \;

set -u

input=$1
output=$2

ffmpeg -i $input -c:v libx264 -an $output

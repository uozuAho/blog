#!/bin/bash
#
# Reduce frame rate of a video. Also converts to h264 and removes audio.
# Note that Safari only very recently supports VP8/webm.
#
# To run in a batch, try:

set -u

input=$1
output=$2

# -an removes audio
ffmpeg -i $input -c:v libx264 -filter:v fps=fps=15 -an $output

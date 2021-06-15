#!/bin/bash
#
# Convert a video to VP8, webm format. Requires ffmpeg.

set -u

input=$1
output=$2

ffmpeg -i $input -c:v libvpx -an $output

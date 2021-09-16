#!/bin/bash
#
# Requires ImageMagick
# Convert given images to webp format
#
# Usage:
#
#   ./batch_image_convert.sh OUT_DIR "/input/file/pattern/*.jpg"
#
# Issues:
# - Changes image resolution! WTF? I can't stop this. I've tried -quality 100,
#   -resize 100%. The images always come out the same.

set -eu

OUT_DIR=$1
PATTERN=$2

mkdir -p $OUT_DIR
magick.exe convert -path $OUT_DIR -format webp -quality 75 $PATTERN

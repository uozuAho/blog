#!/bin/bash
#
# Requires ImageMagick
# Resize to max specified pixels, webp format
#
# Usage:
#
#   ./batch_image_resize.sh OUT_DIR "/input/file/pattern/*.jpg"
#
# To do
# - this rotates some images for some reason, need to open & save in GIMP to fix

set -eu

OUT_DIR=$1
PATTERN=$2
MAX_PIXELS=200000

mkdir -p $OUT_DIR
magick.exe mogrify -resize ${MAX_PIXELS}@ -path $OUT_DIR -format webp -quality 75 $PATTERN

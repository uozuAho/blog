#!/bin/bash
#
# Requires ImageMagick
# Resize to max specified pixels, jpg format.
# Note that Safari only recently supports webp.
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
magick.exe mogrify -resize ${MAX_PIXELS}@ -path $OUT_DIR -format jpg -quality 75 $PATTERN

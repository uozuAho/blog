#!/bin/bash
#
# Prints all matching images as HTML <img> tags.
# Run in this directory. Example:
#
# ./print_image_html.sh "../static/yyyy_mouse/*.webp"
#
# Requires ImageMagick

set -u

PATTERN=$1

for file in $PATTERN; do
  path=`echo $file | sed 's|\.\./static||'`
  echo \<img src=\"$path\"
  echo '  alt=""'
  # insert width and height? Reduces CLS, but messes with aspect ratios on
  # mobiles...
  wh=`magick identify -format 'width="%[fx:w]"' $file`
  echo "  $wh"
  echo "  loding=\""lazy\"" />"
  echo
done

#!/bin/bash

rm -rf public
hugo
# remove blog RSS feed (use home RSS feed)
# Hugo docs are unclear on how to do this.
rm public/blog/index.xml

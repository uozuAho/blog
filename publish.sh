#!/bin/bash
# steps
# local dev
# - proof-read, test on mobile
# - run lighthouse
# branch deploy
# - set draft to false
# - run this script
# - push to branch

rm -rf public
hugo
# remove blog RSS feed (use home RSS feed)
# Hugo docs are unclear on how to do this.
rm public/blog/index.xml

#!/bin/bash

# local dev
# - proof read
# - test on other browsers
# - test on mobile (hugo server -D --bind 0.0.0.0)
# - run lighthouse

# push branch
# - set draft to false
# - run this script
# - push to branch
# - goto https://github.com/uozuAho/blog -> current branch
# - click on the netlify build badge - this shows the branch deployment
# - check percy: click the tick/cross in github -> click on Details of Percy
#   snapshot -> Run npx percy snapshot public -> click the percy link near the
#   top of the logs
# - read in feedly
# - run lighthouse
# - check with original authors if using any content

# final steps
# - merge to main
# - publish (run this script)
# - push
# - goto https://github.com/uozuAho/blog -> check percy

rm -rf public
hugo
# remove blog RSS feed (use home RSS feed)
# Hugo docs are unclear on how to do this.
rm public/blog/index.xml

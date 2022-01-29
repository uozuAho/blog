#!/bin/bash
# steps
# local dev
# - proof read
# - test on other browsers
# - test on mobile (hugo server -D --bind 0.0.0.0)
# - run lighthouse
# branch deploy (netlify subdomain)
# - set draft to false
# - run this script
# - push to branch
# - goto https://github.com/uozuAho/blog -> current branch
# - click on the netlify build badge - this shows the branch deployment
# final steps
# - check with original authors if using any content
# - read in feedly
# - run lighthouse
# - merge to main
# - publish (run this script)
# - push
# - goto https://github.com/uozuAho/blog -> check percy

rm -rf public
hugo
# remove blog RSS feed (use home RSS feed)
# Hugo docs are unclear on how to do this.
rm public/blog/index.xml

#!/bin/bash
# steps
# local dev
# - proof-read, test on mobile
# - run lighthouse
# branch deploy
# - set draft to false
# - run this script
# - push to branch
# - goto github -> current branch
# - click on the netlify build badge - this shows the branch deployment
# OPTIONAL: deploy to iamwoz.com subdomain
# - goto https://app.netlify.com/, log in
# - goto site settings -> domain management -> branch subdomains, do the thing
# - wait a while, while DNS updates (?)
# final steps
# - proof read
# - read in feedly
# - run lighthouse
# - merge to main
# - publish
# - push

rm -rf public
hugo
# remove blog RSS feed (use home RSS feed)
# Hugo docs are unclear on how to do this.
rm public/blog/index.xml

#!/bin/bash

set -u

title=$1
timestamp=$(date +"%Y%m%d")
hugo new content/blog/${timestamp}_${title}.md
mkdir static/blog/${timestamp}_${title}

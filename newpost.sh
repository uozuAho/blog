#!/bin/bash

set -u

title=$1
timestamp=$(date +"%Y%m%d")
echo $timestamp
hugo new content/blog/${timestamp}_${title}.md

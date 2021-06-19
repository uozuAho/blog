#!/bin/bash
#
# print asset sizes

DIR=${1:-static}

du -ah $DIR

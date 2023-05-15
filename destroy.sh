#!/bin/bash
cwd=$(pwd)
cd library/nuke
./nuke.sh $TARGET_AWS_ACCOUNT_ID
cd $cwd

#!/bin/bash
# Clear Cache files and folders
find . -type d -name ".terragrunt-cache" | xargs rm -r 
find . -type d -name ".terraform" | xargs rm -r 
find . -type f -name ".terraform.lock.hcl" | xargs rm
find . -type f -name ".tgpid" | xargs rm
find . -type f -name "*.log" | xargs rm
find . -type f -name "config.hcl" | xargs rm
find . -type d -name "temp" | xargs rm -r 

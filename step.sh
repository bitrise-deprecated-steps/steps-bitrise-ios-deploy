#!/bin/bash
  
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ruby "${THIS_SCRIPT_DIR}/bitrise_build_uploader.rb"
exit $?
#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# load bash utils
source "${THIS_SCRIPT_DIR}/bash_utils/utils.sh"
source "${THIS_SCRIPT_DIR}/bash_utils/formatted_output.sh"

print_and_do_command_exit_on_error cd "${THIS_SCRIPT_DIR}"
print_and_do_command_exit_on_error bundle install

print_and_do_command_exit_on_error bundle exec ruby ./bitrise_build_uploader.rb
exit $?
#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# load bash utils
source "${THIS_SCRIPT_DIR}/bash_utils/utils.sh"
source "${THIS_SCRIPT_DIR}/bash_utils/formatted_output.sh"


# ------------------------------
# --- Error Cleanup

function finalcleanup {
  echo "-> finalcleanup"
  local fail_msg="$1"

  write_section_to_formatted_output "# Error"
  if [ ! -z "${fail_msg}" ] ; then
    write_section_to_formatted_output "**Error Description**:"
    write_section_to_formatted_output "${fail_msg}"
  fi
  write_section_to_formatted_output "*See the logs for more information*"
}

function CLEANUP_ON_ERROR_FN {
  local err_msg="$1"
  finalcleanup "${err_msg}"
}
set_error_cleanup_function CLEANUP_ON_ERROR_FN


# ------------------------------
# --- Utils - Keychain

function create_and_activate_keychain {
	local keychain_path="$1"
	local keychain_psw="$2"

    # Create the keychain
    if [ ! -f "${keychain_path}" ] ; then
    	print_and_do_command_exit_on_error security -v create-keychain -p "${keychain_psw}" "${keychain_path}"
    fi

    # Unlock keychain
    print_and_do_command_exit_on_error security -v list-keychains -s "${keychain_path}"
    print_and_do_command_exit_on_error security -v list-keychains
    print_and_do_command_exit_on_error security -v unlock-keychain -p "${keychain_psw}" "${keychain_path}"
    print_and_do_command_exit_on_error security -v set-keychain-settings -lut 72000 "${keychain_path}"
    print_and_do_command_exit_on_error security -v default-keychain -s "${keychain_path}"
}


# ------------------------------
# --- Main

# a default, open keychain is required for Provisioning Profile analyzer
keychain_dir_path="${HOME}/bitrise-deploy"
keychain_password="bitrise_deploy"
print_and_do_command_exit_on_error mkdir -p "${keychain_dir_path}"
create_and_activate_keychain "${keychain_dir_path}/bitrise_deploy.keychain" "${keychain_password}"
fail_if_cmd_error "Failed to create keychain"


print_and_do_command_exit_on_error cd "${THIS_SCRIPT_DIR}"
print_and_do_command_exit_on_error bundle install

print_and_do_command_exit_on_error bundle exec ruby ./bitrise_build_uploader.rb
exit $?
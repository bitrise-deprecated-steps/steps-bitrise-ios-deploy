require 'json'
require 'net/http'
require 'uri'


# ----------------------------
# --- Options

options = {
	build_url: ENV['STEP_BITRISE_IOS_DEPLOY_BUILD_URL'],
	api_token: ENV['STEP_BITRISE_IOS_DEPLOY_API_TOKEN'],
	ipa_path: ENV['STEP_BITRISE_IOS_DEPLOY_IPA_PATH'],
}

puts "Options: #{options}"


# ----------------------------
# --- Formatted Output

$formatted_output_file_path = ENV['STEPLIB_FORMATTED_OUTPUT_FILE_PATH']

def puts_string_to_formatted_output(text)
	puts text

	unless $formatted_output_file_path.nil?
		open($formatted_output_file_path, 'a') { |f|
			f.puts(text)
		}
	end
end

def puts_section_to_formatted_output(section_text)
	puts
	puts section_text
	puts

	unless $formatted_output_file_path.nil?
		open($formatted_output_file_path, 'a') { |f|
			f.puts
			f.puts(section_text)
			f.puts
		}
	end
end


# ----------------------------
# --- Cleanup

def cleanup_before_error_exit(reason_msg=nil)
	puts " [!] Error: #{reason_msg}"
	puts_section_to_formatted_output("## Failed")
	unless reason_msg.nil?
		puts_section_to_formatted_output(reason_msg)
	end
	puts_section_to_formatted_output("Check the Logs for details.")
end


begin
	# - Option checks
	raise "No Build URL provided" unless options[:build_url]
	raise "No Build API Token provided" unless options[:api_token]
	raise "No IPA path provided" unless options[:ipa_path]
	raise "IPA does not exist at the provided path" unless File.exists?(options[:ipa_path])

	# - Create a Build Artifact on Bitrise
	ipa_file_name = File.basename(options[:ipa_path])

	uri = URI("#{options[:build_url]}/artifacts.json")
	raw_resp = Net::HTTP.post_form(uri, {
		'api_token' => options[:api_token],
		'title' => ipa_file_name,
		'filename' => ipa_file_name,
		'artifact_type' => 'ios-ipa'
		})
	puts "* raw_resp: #{raw_resp}"
	unless raw_resp.code == '200'
		raise "Failed to create the Build Artifact on Bitrise - code: #{raw_resp.code}"
	end
	parsed_resp = JSON.parse(raw_resp.body)
	puts "* parsed_resp: #{parsed_resp}"
	
	unless parsed_resp['error_msg'].nil?
		raise "Failed to create the Build Artifact on Bitrise: #{parsed_resp['error_msg']}"
	end

	upload_url = parsed_resp['upload_url']
	raise "No upload_url provided for the artifact" if upload_url.nil?
	artifact_id = parsed_resp['id']
	raise "No artifact_id provided for the artifact" if artifact_id.nil?

	# - Upload the IPA
	puts "* upload_url: #{upload_url}"

	unless system("curl --fail --silent -T '#{options[:ipa_path]}' -X PUT '#{upload_url}'")
		raise "Failed to upload the Artifact file"
	end

	# - Finish the Artifact creation
	uri = URI("#{options[:build_url]}/artifacts/#{artifact_id}/finish_upload.json")
	puts "* uri: #{uri}"
	raw_resp = Net::HTTP.post_form(uri, {
		'api_token' => options[:api_token]
		})
	puts "* raw_resp: #{raw_resp}"
	unless raw_resp.code == '200'
		raise "Failed to send 'finished' to Bitrise - code: #{raw_resp.code}"
	end
	parsed_resp = JSON.parse(raw_resp.body)
	puts "* parsed_resp: #{parsed_resp}"
	unless parsed_resp['status'] == 'ok'
		raise "Failed to send 'finished' to Bitrise"
	end

	# - Success
	puts_section_to_formatted_output("## Success")
	#
	puts_section_to_formatted_output("You can find the Artifact on Bitrise, on the [Build's page](#{options[:build_url]})")
rescue => ex
	cleanup_before_error_exit "#{ex}"
	exit 1
end

exit 0
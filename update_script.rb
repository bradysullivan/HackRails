require 'logger'
require 'net/smtp'
require 'rubygems'

@last_result = nil
@default_proc = nil

def result_matches(regex)
	return !regex.match(@last_result).nil? if regex.class = "Regex"
	return !Regex.new(regex).match(@last_result).nil?
end

def do_command(command, &block)
	@last_result = `#{command} 2>&1`
	while not $?.exited? do
	end
	if $?.success?
		block.call(@last_result, command) if !block.nil?
	else
		@default_proc.call(@last_result, command) if !@default_proc.nil?
	end
	return $?.success?
end

def split_result(char="\n")
	return @last_result.split(char)
end

def alert_email( emails, command, result)
	message = <<MESSAGE_END
From: hackrails updater <hackrails.updater.noreply@gmail.com>
To: #{emails.join(",")}
Subject: Update Failure!!

Fatal error while executing `#{command}` during update!
Output:
#{result}
MESSAGE_END
	smtp = Net::SMTP.new 'smtp.gmail.com', 587
	smtp.enable_starttls
	smtp.start(Socket.gethostname,"hackrails.updater.noreply@gmail.com","niggerfaggot",:login) do |server|
    server.send_message message, "hackrails.updater.noreply@gmail.com", emails
	end
end

def log_result(value, status, command)
	logger = Logger.new("update_logs")
	logger.add(Logger::FATAL, value, command)
	logger.close
end

def error_proc(result, command)
	puts "penis"
	log_result(result, $?.exitstatus, command)
	puts "Error running command `#{command}`. Check update_logs for more information"
	alert_email ["brady.sullivan@iwsinc.com", "pdebus@iwsinc.com"], command, result
	exit
end

def get_changed_files
	do_command "git diff --name-status ORIG_HEAD.. | grep ^M | cut -f 2"
	return split_result
end

def handle_changed_files(changed_files)
	changed_files = get_changed_files if changed_files.nil?
	changed_files.each do |file|
		case file
		when 'Gemfile'
			do_command 'bundle install'
		end
	end
end

@default_proc = method(:error_proc)

handle_changed_files if ARGV.include? '--changed_files'

loop do
	sleep 15
	do_command "git pull"
	next if result_matches(/Already up-to-date\./)
	changed_files = get_changed_files
	restart_script = true if changed_files.include? 'update_script.rb'
	handle_changed_files(changed_files) if !restart_script
	# Do things that need to be done before the script is restarted if it needs to be
	do_command "bundle exec rake db:migrate"

	# Restart the script if the script has changed
	do_command 'ruby update_script_controller.rb restart -- --changed_files' if restart_script
end


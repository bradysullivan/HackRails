require 'logger'
require 'net/smtp'
require 'rubygems'

@success = true
@result = nil

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

def do_command(command, exit_if_failed=true)
	@result = `#{command} 2>&1`
	while not $?.exited?
	end
	if not $?.success?
		@success = false
		log_result(@result, $?.exitstatus, command)
		puts "Error running command `#{command}`. Check update_logs for more information"
		alert_email ["brady.sullivan@iwsinc.com", "pdebus@iwsinc.com"], command, @result
		return false if !exit_if_failed else exit
	end
	return true
end

def result_matches(regex)
	return !regex.match(@result).nil?
end

while @success do
	sleep 15 if @success
	do_command "git pull"
	next if result_matches(/Already up-to-date\./)
	do_command "bundle exec rake db:migrate"
end


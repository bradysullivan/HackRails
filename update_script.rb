@success = true
@result = nil

def log_result(value, status, command)
	logger = Logger.new("update_logs")
	logger.add(Logger::FATAL, value, command)
	logger.close
end

def do_command(command)
	@result = `#{command} 2>&1`
	while not $?.exited?
	end
	if not $?.success?
		log_result(@result, $?.exitstatus, command)
		puts "Error running command `#{command}`. Check update_logs for more information"
		alert_email ["fashizzlepop@gmail.com", "debus.phil@gmail.com"], command, @result
		return false
	end
	return true
end

def result_matches(regex)
	return !regex.match(@result).nil?
end

while @success do
	do_command "git pull"
	next if result_matches(/Already up-to-date\./)
	do_command "bundle exec rake db:migrate"
	sleep 15 if @success
end


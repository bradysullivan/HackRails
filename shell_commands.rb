module ShellCommands
	@last_result = nil
	@default_proc = nil

	def result_matches(regex)
		return !regex.match(@last_result).nil? if regex.class = "Regex"
		return !Regex.new(regex).match(@last_result).nil?
	end
	
	def do_command(command, execute_block_if_failed=false, &block)
		@last_result = `#{command} 2>&1`
		while not $?.exited? do
		end
		if $?.success?
				_call_block(command, block) if !execute_block_if_failed
			return true
		else
			_call_block(command, block) if execute_block_if_failed
			return false
		end
	end

	def split_result(char="\n")
		return @last_result.split(char)
	end
	
private
	def _call_block(command, block)
		if !block.nil?
			block.call(@last_result, command)
		elsif !@default_proc.nil?
			@default_proc.call(@last_result, command)
		end
	end
end
class Update < ActiveRecord::Base
  attr_accessible :after, :before, :commits, :ref
  serialize :commits, Array

  def self.allowed_ips
    %w[207.97.227.253 50.57.128.197 108.171.174.178 50.57.231.61 204.232.175.64 192.30.252.0 204.232.175.75]
  end

  def apply_update
    begin
      do_command "git pull"
      return true if result_matches(/Already up-to-date/)
      do_command "bundle install"
      do_command "bundle exec rake db:migrate"
      do_command "rvmsudo passenger stop -p 80 && rvmsudo passenger start -p 80 --user=ubuntu" if Rails.application.config.cache_classes  
    rescue ShellCommandFailure => e
      Update.error_proc(e.result)
      return false
    end
    return true
  end

  def self.alert_email( emails, result)
    message = "Fatal error while executing `#{result["command"]}` during update!\nOutput:\n\t#{result["result"]}"
    ActionMailer::Base.mail(:from => 'hackrails.updater.noreply@gmail.com', :to => emails, :subject => "Update Failure!!", :body => message).deliver
  end

  def self.log_result(result)
    logger = Logger.new("update_logs")
    logger.add(Logger::FATAL, result["result"], result["result"])
    logger.close
  end

  def self.error_proc(result)
    log_result(result)
    alert_email ["brady.sullivan@iwsinc.com", "pdebus@iwsinc.com"], result
  end
end

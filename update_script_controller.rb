require 'rubygems'        # if you use RubyGems
require 'daemons'

options = {
  :app_name   => "HackRails_Updater",
  :backtrace  => true,
}


Daemons.run('update_script.rb')
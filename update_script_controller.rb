require 'rubygems'        # if you use RubyGems
require 'daemons'

options = {
  :app_name   => "hack_rails_updater",
  :backtrace  => true,
}


Daemons.run('update_script.rb', options)
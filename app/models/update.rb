class Update < ActiveRecord::Base
  attr_accessible :after, :before, :commits, :ref
  serialize :commits, Array

  ALLOWED_IPS = %w[207.97.227.253 50.57.128.197 108.171.174.178 50.57.231.61 204.232.175.64 192.30.252.0]

  def apply_update
  end
end

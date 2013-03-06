class Update < ActiveRecord::Base
  attr_accessible :after, :before, :commits, :ref
  serialize :commits, Array

  def apply_update

  end
end

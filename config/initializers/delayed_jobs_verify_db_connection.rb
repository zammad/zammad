require 'delayed_job'

module Delayed
  class Job < ::ActiveRecord::Base

    def self.recover_from(_error)
      ::ActiveRecord::Base.connection.verify!
    end
  end
end

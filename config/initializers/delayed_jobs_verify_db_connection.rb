# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'delayed_job'

module Delayed
  class Job < ::ActiveRecord::Base

    def self.recover_from(_error)
      ::ActiveRecord::Base.connection.verify!
    end
  end
end

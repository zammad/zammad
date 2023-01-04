# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'delayed_job'

module Delayed
  class Job < ::ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord

    def self.recover_from(_error)
      ::ActiveRecord::Base.connection.verify!
    end
  end
end

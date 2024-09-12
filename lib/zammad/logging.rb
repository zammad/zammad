# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module Logging
    def self.extend_logging_to_stdout
      console = ActiveSupport::Logger.new($stdout)
      console.formatter = Rails.logger.formatter
      console.level = Rails.logger.level

      Rails.logger.broadcast_to(console)
    end
  end
end

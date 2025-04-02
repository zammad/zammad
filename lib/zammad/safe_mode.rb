# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module SafeMode
    def self.enabled?
      %w[1 true].include?(ENV['ZAMMAD_SAFE_MODE']) && !Rails.const_defined?(:Server)
    end

    def self.continue_or_exit!
      return if enabled?

      exit! # rubocop:disable Rails/Exit
    end

    def self.hint
      return if !enabled?

      warn 'Zammad is running in safe mode. Any third-party services like Redis are ignored.'
      warn ''
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::Match::EmailRegex
  def self.match(value:, match_rule:, check_mode: false)
    begin
      return value.match?(%r{#{match_rule}}i)
    rescue => e
      message = "Can't use regex '#{match_rule}' on '#{value}': #{e.message}"
      Rails.logger.error message
      raise message if check_mode == true
    end

    false
  end
end

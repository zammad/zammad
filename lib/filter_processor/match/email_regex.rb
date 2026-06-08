# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FilterProcessor::Match::EmailRegex
  def self.match(value:, match_rule:, check_mode: false, context: nil)
    return false if value.blank?

    match_data = value.match(%r{#{match_rule}}i)

    return false if !match_data

    if context.try(:fetch, :match_data).is_a?(Hash)
      match_data.captures.each.with_index(1) do |capture, index|
        context[:match_data][index.to_s] = capture
      end

      context[:match_data].merge!(match_data.named_captures)
    end

    true
  rescue => e
    message = "Can't use regex '#{match_rule}' on '#{value}': #{e.message}"
    Rails.logger.error message
    raise message if check_mode == true

    false
  end
end

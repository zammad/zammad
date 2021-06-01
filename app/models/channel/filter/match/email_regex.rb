# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::Match::EmailRegex

  def self.match(value:, match_rule:, check_mode: false)
    regexp = false
    if match_rule =~ %r{^(regex:)(.+?)$}
      regexp = true
      match_rule = $2
    end

    if regexp == false
      match_rule_quoted = Regexp.quote(match_rule).gsub(%r{\\\*}, '.*')
      return true if value.match?(%r{#{match_rule_quoted}}i)

      return false
    end

    begin
      return true if value.match?(%r{#{match_rule}}i)

      return false
    rescue => e
      message = "Can't use regex '#{match_rule}' on '#{value}': #{e.message}"
      Rails.logger.error message
      raise message if check_mode == true
    end

    false
  end
end

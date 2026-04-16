# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FilterProcessor::Match::EndsWith
  def self.match(value:, match_rule:)
    match_rule.any? { |rule_value| value.downcase.end_with? rule_value.downcase }
  end
end

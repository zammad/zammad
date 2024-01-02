# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::Match::Contains

  def self.match(value:, match_rule:)
    match_rule_quoted = Regexp.quote(match_rule).gsub(%r{\\\*}, '.*')

    value.match?(%r{#{match_rule_quoted}}i)
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class PostmasterFilter < ApplicationModel
  include ChecksHtmlSanitized

  store     :perform
  store     :match
  validates :name,    presence: true
  validates :perform, 'validations/verify_perform_rules': true

  before_create :validate_condition
  before_update :validate_condition

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  VALID_OPERATORS = [
    'contains',
    'contains not',
    'is any of',
    'is none of',
    'starts with one of',
    'ends with one of',
    'matches regex',
    'does not match regex',
  ].freeze

  def validate_condition
    raise Exceptions::UnprocessableEntity, __('At least one match rule is required, but none was provided.') if match.blank?

    match.each_value do |meta|
      raise Exceptions::UnprocessableEntity, __('The provided match operator is missing or invalid.') if meta['operator'].blank? || VALID_OPERATORS.exclude?(meta['operator'])
      raise Exceptions::UnprocessableEntity, __('The required match value is missing.') if meta['value'].blank?

      validate_regex_match_rule!(meta['value'], meta['operator'])
    end
    true
  end

  private

  def validate_regex_match_rule!(match_rule, operator)
    return if !operator.eql?('matches regex') && !operator.eql?('does not match regex')

    Channel::Filter::Match::EmailRegex.match(value: 'test content', match_rule: match_rule, check_mode: true)
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end
end

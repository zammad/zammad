# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  def validate_condition
    raise Exceptions::UnprocessableEntity, __('At least one match rule is required, but none was provided.') if match.blank?

    match.each_value do |meta|
      raise Exceptions::UnprocessableEntity, __('The provided match operator is missing or invalid.') if meta['operator'].blank? || meta['operator'] !~ %r{^(contains|contains not)$}
      raise Exceptions::UnprocessableEntity, __('The required match value is missing.') if meta['value'].blank?

      begin
        Channel::Filter::Match::EmailRegex.match(value: 'test content', match_rule: meta['value'], check_mode: true)
      rescue => e
        raise Exceptions::UnprocessableEntity, e.message
      end
    end
    true
  end

end

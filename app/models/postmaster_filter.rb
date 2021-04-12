# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PostmasterFilter < ApplicationModel
  include ChecksHtmlSanitized

  store     :perform
  store     :match
  validates :name, presence: true

  before_create :validate_condition
  before_update :validate_condition

  sanitized_html :note

  def validate_condition
    raise Exceptions::UnprocessableEntity, 'Min. one match rule needed!' if match.blank?

    match.each_value do |meta|
      raise Exceptions::UnprocessableEntity, 'operator invalid, ony "contains" and "contains not" is supported' if meta['operator'].blank? || meta['operator'] !~ %r{^(contains|contains not)$}
      raise Exceptions::UnprocessableEntity, 'value invalid/empty' if meta['value'].blank?

      begin
        Channel::Filter::Match::EmailRegex.match(value: 'test content', match_rule: meta['value'], check_mode: true)
      rescue => e
        raise Exceptions::UnprocessableEntity, e.message
      end
    end
    true
  end

end

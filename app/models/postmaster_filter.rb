# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class PostmasterFilter < ApplicationModel
  store     :perform
  store     :match
  validates :name, presence: true

  before_create :validate_condition
  before_update :validate_condition

  def validate_condition
    raise Exceptions::UnprocessableEntity, 'Min. one match rule needed!' if match.blank?
    match.each { |_key, meta|
      raise Exceptions::UnprocessableEntity, 'operator invalid, ony "contains" and "contains not" is supported' if meta['operator'].blank? || meta['operator'] !~ /^(contains|contains not)$/
      raise Exceptions::UnprocessableEntity, 'value invalid/empty' if meta['value'].blank?
      begin
        if meta['operator'] == 'contains not'
          Channel::Filter::Database.match('test content', meta['value'], false, true)
        else
          Channel::Filter::Database.match('test content', meta['value'], true, true)
        end
      rescue => e
        raise Exceptions::UnprocessableEntity, e.message
      end
    }
    true
  end

end

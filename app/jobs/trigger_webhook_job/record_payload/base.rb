# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggerWebhookJob::RecordPayload::Base

  USER_ATTRIBUTE_BLACKLIST = %w[
    last_login
    login_failed
    password
    preferences
    group_ids
    groups
    authorization_ids
    authorizations
  ].freeze

  attr_reader :record

  def initialize(record)
    @record = record
  end

  def generate
    reflect_on_associations.each_with_object(record_attributes) do |association, result|
      result[association.name.to_s] = resolved_association(association)
    end
  end

  def resolved_association(association)
    id = record_attributes["#{association.name}_id"]
    return {} if id.blank?

    associated_record = association.klass.lookup(id: id)
    associated_record_attributes(associated_record)
  end

  def record_attributes
    @record_attributes ||= attributes_with_association_names(record)
  end

  def reflect_on_associations
    record.class.reflect_on_all_associations.select do |association|
      self.class.const_get(:ASSOCIATIONS).include?(association.name)
    end
  end

  def associated_record_attributes(record)
    return {} if record.blank?

    attributes = attributes_with_association_names(record)
    return attributes if !record.instance_of?(::User)

    attributes.except(*USER_ATTRIBUTE_BLACKLIST)
  end

  def attributes_with_association_names(record)
    record.attributes_with_association_names.sort.to_h
  end
end

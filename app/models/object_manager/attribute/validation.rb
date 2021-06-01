# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager::Attribute::Validation < ActiveModel::Validator
  include ::Mixin::HasBackends

  def validate(record)
    return if validation_unneeded?

    @record = record
    sanitize_memory_cache

    return if attributes_unchanged?

    model_attributes.select(&:editable).each do |attribute|
      perform_validation(attribute)
    end
  end

  private

  attr_reader :record

  def validation_unneeded?
    return true if Setting.get('import_mode')

    ApplicationHandleInfo.current != 'application_server'
  end

  def attributes_unchanged?
    model_attributes.none? do |attribute|
      record.will_save_change_to_attribute?(attribute.name)
    end
  end

  def model_attributes
    @model_attributes ||= begin
      object_lookup_id = ObjectLookup.by_name(record.class.name)
      @active_attributes.select { |attribute| attribute.object_lookup_id == object_lookup_id }
    end
  end

  def perform_validation(attribute)
    backends.each do |backend|
      backend.validate(
        record:    record,
        attribute: attribute
      )
    end
  end

  def sanitize_memory_cache
    @model_attributes = nil

    latest_cache_key = active_attributes_in_db.cache_key
    return if @previous_cache_key == latest_cache_key

    @previous_cache_key = latest_cache_key
    @active_attributes  = active_attributes_in_db.to_a
  end

  def active_attributes_in_db
    ObjectManager::Attribute.where(active: true)
  end
end

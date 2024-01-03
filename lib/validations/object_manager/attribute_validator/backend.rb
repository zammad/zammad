# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::ObjectManager::AttributeValidator::Backend
  def self.validate(...)
    new(...).validate
  end

  attr_reader :record, :attribute, :value, :previous_value

  def initialize(record:, attribute:)
    @record         = record
    @attribute      = attribute
    @value          = record[attribute.name]
    @previous_value = record.attribute_in_database(attribute.name)
  end

  def invalid_because_attribute(message, **)
    record.errors.add attribute.name.to_sym, message, **
  end
end

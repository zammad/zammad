class ObjectManager::Attribute::Validation::Backend
  include Mixin::IsBackend

  def self.inherited(subclass)
    subclass.is_backend_of(::ObjectManager::Attribute::Validation)
  end

  def self.validate(*args)
    new(*args).validate
  end

  attr_reader :record, :attribute, :value, :previous_value

  def initialize(record:, attribute:)
    @record         = record
    @attribute      = attribute
    @value          = record[attribute.name]
    @previous_value = record.attribute_in_database(attribute.name)
  end

  def invalid_because_attribute(message)
    record.errors.add attribute.name.to_sym, message
  end
end

Mixin::RequiredSubPaths.eager_load_recursive(__dir__)

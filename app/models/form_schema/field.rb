# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field

  # Registers new attributes in the current class object.
  def self.attribute(*names)
    names.each do |name|
      @attributes ||= []
      @attributes << name
      attr_accessor name
    end
  end

  class << self
    attr_reader :attributes
  end

  # Add base attributes
  attribute :show, :type, :name, :label, :labelPlaceholder, :value, :help, :id, :disabled, :delay, :errors, :sectionsSchema, :classes, :validation, :validationMessage, :validationVisibility, :outerClass, :wrapperClass, :labelClass, :prefixClass, :innerClass, :suffixClass, :inputClass, :helpClass, :messagesClass, :messageClass, :required

  # Type of the current field object. By default, this is inferred from the
  #   class name; override if needed.
  def self.type
    name.split('::').last.downcase
  end

  # See FormSchema::Form.context.
  attr_reader :context

  def initialize(context:, **attributes)
    @context = context
    attributes.each do |key, value|
      send(:"#{key}=", value)
    end
  end

  # Get attributes common to all fields, such as name, id etc.
  def self.base_attributes
    FormSchema::Field.attributes
  end

  # Get defined attributes of the current instance class and its parents, excluding FormSchema::Field which has the base attributes.
  def self.instance_attributes
    attributes = []
    [self, *ancestors.select { |klass| klass.name.starts_with? 'FormSchema::Field::' }].each do |klass|
      attributes += klass.attributes if klass.attributes
    end
    attributes
  end

  def attribute_values(attributes)
    result = {}
    attributes.each do |attribute|
      value = send(attribute.to_sym)
      result[attribute] = value if !value.nil?
    end
    result
  end

  # If the context responds to :schema, use it to map the ids to GraphQL::ID strings.
  def id_from_object(object)
    context.try(:schema)&.id_from_object(object) || object.id
  end

  def schema
    klass = self.class
    result = { type: klass.type, props: attribute_values(klass.instance_attributes) }
    result.merge attribute_values(klass.base_attributes)
  end
end

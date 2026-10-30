# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Gate for every chain step of a template written in the admin interface, so a placeholder cannot
# step from a record to its class, into a model holding credentials, or from a string to a constant.
class NotificationFactory::Renderer::ObjectAccess
  MODELS = {
    'Ticket'                  => %w[tag_list current_state_color],
    'Ticket::Article'         => %w[body_as_html body_as_text body_as_text_with_quote],
    'User'                    => %w[fullname longname avatar],
    'Organization'            => [],
    'Group'                   => %w[fullname],
    'Ticket::State'           => [],
    'Ticket::Priority'        => [],
    'Ticket::Article::Type'   => [],
    'Ticket::Article::Sender' => [],
  }.freeze

  WITHHELD_COLUMNS = %w[password preferences].freeze

  OBJECTS = {
    'ExternalDataSource' => %w[term],
  }.freeze

  VALUE_CLASSES = [
    String, Integer, Float, BigDecimal, TrueClass, FalseClass, NilClass,
    Time, Date, DateTime, ActiveSupport::TimeWithZone, Hash, Array,
  ].freeze
  VALUE_METHODS = %w[first last downcase upcase strip to_s text2html size count].freeze

  COLLECTION_METHODS = %w[first last count size].freeze

  attr_reader :object

  def self.allows?(object, method)
    new(object).allows?(method)
  end

  def initialize(object)
    @object = object
  end

  def allows?(method)
    return false if object.is_a?(Module)
    return VALUE_METHODS.include?(method) if value?
    return COLLECTION_METHODS.include?(method) if object.is_a?(ActiveRecord::Relation)
    return object.class.members.include?(method.to_sym) if object.is_a?(Struct)
    return OBJECTS[object.class.name].include?(method) if OBJECTS.key?(object.class.name)
    return model_methods.include?(method) if model?

    false
  end

  private

  def value?
    VALUE_CLASSES.any? { |klass| object.instance_of?(klass) }
  end

  def model?
    object.is_a?(ActiveRecord::Base) && MODELS.key?(object.class.name)
  end

  def model_methods
    klass = object.class

    (klass.column_names - WITHHELD_COLUMNS) + association_names(klass) + MODELS[klass.name]
  end

  def association_names(klass)
    klass.reflect_on_all_associations
      .reject { |reflection| reflection.options[:polymorphic] }
      .select { |reflection| MODELS.key?(reflection.class_name) }
      .map { |reflection| reflection.name.to_s }
  end
end

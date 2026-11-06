# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How a field of a record is read and set, by the field's data type: one class per type in this directory, found by
#   its file, so that an addon adds a type with a file of its own. A field whose type has no
#   class is shown as it is stored and cannot be set.
#
# A caller names a value as people know it — an option's label, an agent's name or email —, and #resolve turns it into
#   what the record stores, or raises Service::EntityAttribute::Invalid with the candidates or the valid values. Only
#   values the user may use are matched and named, so that no value behind a permission shows.
class Service::EntityAttribute::Type
  Invalid = Service::EntityAttribute::Invalid
  Option  = Service::EntityAttribute::Option

  class_attribute :data_types, instance_accessor: false, default: [].freeze
  class_attribute :relation, instance_accessor: false

  class << self
    # @param attribute [ObjectManager::Attribute] the field
    # @param user [User] who reads or sets the field
    # @param record [ApplicationModel, nil] the record whose field it is, where the values depend on it
    def for(attribute, user:, record: nil)
      raise ArgumentError, 'a field is read for a user, or for nobody through Type.unscoped' if user.nil?

      class_for(attribute).new(attribute, user:, record:)
    end

    # The field for a caller that acts for nobody, such as an AI agent a trigger runs: every value it has, without a
    #   user's permissions.
    def unscoped(attribute)
      class_for(attribute).new(attribute, user: nil)
    end

    private

    # A class for the field's relation first, such as the ticket's state among the selects, else one for its data type.
    def class_for(attribute)
      typed    = descendants.select { |candidate| candidate.data_types.include?(attribute.data_type) }
      relation = attribute.data_option.with_indifferent_access[:relation].presence

      typed.find { |candidate| candidate.relation.present? && candidate.relation == relation } ||
        typed.find { |candidate| candidate.relation.nil? } ||
        self
    end

    # @param types [Array<String>] the data types of ObjectManager::Attribute the class reads and sets
    # @param relation [String, nil] the model a select's values are records of, such as 'TicketState'
    def handles(*types, relation: nil)
      self.data_types = types.freeze
      self.relation   = relation
    end
  end

  attr_reader :attribute, :user, :record

  def initialize(attribute, user:, record: nil)
    @attribute = attribute
    @user      = user
    @record    = record
  end

  def name
    attribute.name
  end

  # The key of the value in a record's data, as the update service takes it.
  def data_key
    name
  end

  # @return [Object, nil] what a reader sees of a stored value, a label where the type has one; nil for one the user may
  #   not see
  def label(value)
    value
  end

  # Whether the field holds free text, which whoever filled it may have written.
  def free_text?
    false
  end

  # @return [Object] the value as plain text, for a free-text field
  def plain(value)
    value
  end

  def settable?
    false
  end

  # @return [Hash] the JSON Schema of a value a caller passes
  def value_schema
    {}
  end

  # @param value [Object] as the caller passed it, nil to empty the field
  # @param allowed [Array<String>, nil] the stored values Core Workflow allows, nil for every value: a name is matched
  #   against these only
  # @return [Object] what the record stores
  # @raise [Service::EntityAttribute::Invalid]
  def resolve(value, allowed: nil)
    raise Invalid.new('not_settable', reason: :not_settable, field: name) if !settable?
    return empty_value if value.nil?

    convert(value, allowed:)
  end

  # The values a caller may choose, for a type with a list of them.
  #
  # @param allowed [Array<String>, nil] the stored values Core Workflow allows, nil for every value
  # @return [Array<Array(String, String)>, nil] each value as stored and its label, nil for a type without a list
  def choices(allowed: nil)
    nil
  end

  # The values as a form lists them, in the admin's order: each by its own label, a tree with its parents.
  #
  # @param allowed [Array<String>, nil] the stored values Core Workflow allows, nil for every value
  # @return [Array<Service::EntityAttribute::Option>, nil] nil for a type without a list
  def option_list(allowed: nil)
    nil
  end

  private

  # @return [Object] what the record stores for the value a caller passed
  def convert(value, **)
    value
  end

  def empty_value
    nil
  end

  def options
    attribute.data_option.with_indifferent_access
  end

  def unscoped?
    user.nil?
  end

  # Options kept as a hash, by their keys as text; an option without a label is none.
  def hash_option_list(pairs, allowed)
    pairs.to_h.filter_map do |key, label|
      next if label.blank? || (!allowed.nil? && allowed.exclude?(key.to_s))

      Option.new(value: key.to_s, label: label.to_s)
    end
  end

  # @param reason [Symbol] the kind of value the field takes, or the bound the value is beyond
  def invalid(reason, value: nil, **details)
    raise Invalid.new('invalid_value', reason:, field: name, value:, details:)
  end

  # A record not saved yet, whose fields the create form offers.
  def new_record?
    record.respond_to?(:new_record?) && record.new_record?
  end

  # Last, because loading the types runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end

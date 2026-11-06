# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The field layer's type of each field of a form (Service::EntityAttribute::Type), for the user and the record the
#   form is for, so that the form lists a field's options as the layer's other clients do.
class FormUpdater::FieldTypes
  attr_reader :object_type, :user, :record

  # @param record [ApplicationModel, nil] the record the form shows, a new one on a create form, nil for several
  def initialize(object_type:, user:, record:)
    @object_type = object_type
    @user        = user
    @record      = record
  end

  # @return [Service::EntityAttribute::Type, nil] nil for a field the layer does not list for this form
  def [](name)
    return types[name] if types.key?(name)

    types[name] = lookup(name)
  end

  private

  def types
    @types ||= {}
  end

  # One query for the form's fields, as it asks for each of them on every change.
  def attributes
    @attributes ||= ObjectManager::Attribute.where(object_lookup_id: ObjectLookup.by_name(object_type.name)).index_by(&:name)
  end

  def lookup(name)
    attribute = attributes[name]
    return if attribute.nil?

    type = Service::EntityAttribute::Type.for(attribute, user:, record:)
    return type if !type.is_a?(Service::EntityAttribute::Type::Relation)

    # The layer chooses records for agents on tickets; elsewhere the form's relation classes do.
    type if object_type == ::Ticket && user.permissions?('ticket.agent')
  end
end

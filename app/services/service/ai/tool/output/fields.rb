# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The custom fields of a record as GraphQL lists them for the user — a ticket's, a customer's or an organization's —,
#   by their technical names, each value by its label (Service::EntityAttribute::Label). A caller reads the
#   record's attributes once and passes them on: each read asks the database and builds every attribute's element.
class Service::AI::Tool::Output::Fields
  class << self
    # @return [Array<ObjectManager::Attribute>] the custom fields the user may see
    def attributes(record, user:)
      ObjectManager::Object.new(record.class.name).attributes(user, record, data_only: false)
        .map(&:attribute)
        .select { |attribute| attribute.editable && !attribute.internal }
    end

    # @return [Hash{String => Object}] the fields that hold a value
    def values(record, attributes:, user:)
      attributes.each_with_object({}) do |attribute, fields|
        value = record[attribute.name]
        next if value.nil? || value == '' || value == []

        label = Service::EntityAttribute::Label.with_current_user(user).execute(attribute:, value:)
        fields[attribute.name] = label if !label.nil?
      end
    end

    # The fields that hold free text, which whoever filled them may have written.
    #
    # @return [Array<String>]
    def free_text_names(attributes)
      attributes.select { |attribute| Service::EntityAttribute::Type.unscoped(attribute).free_text? }.map(&:name)
    end

    # Free text as plain text, without the markup of a rich text field.
    def plain(attributes, name, value)
      attribute = attributes.find { |candidate| candidate.name == name }

      attribute ? Service::EntityAttribute::Type.unscoped(attribute).plain(value) : value
    end
  end
end

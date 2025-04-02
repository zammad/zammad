# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ChecksHumanChanges
  extend ActiveSupport::Concern

  def human_changes(record_changes, record, user = nil)
    return {} if record_changes.blank?

    locale = user.try(:locale) || Setting.get('locale_default') || 'en-us'
    attribute_list = allowed_attributes(record.class.name, user)
    user_related_changes = user_changes(record_changes, attribute_list)

    readable_changes(record, user_related_changes, attribute_list, locale)
  end

  private

  def allowed_attributes(object, user)
    ObjectManager::Object.new(object).attributes(user, skip_permission: user.nil?).index_by { |item| item[:name] }
  end

  def user_changes(record_changes, attribute_list)
    user_related_changes = {}
    record_changes.each do |key, value|
      # If no config exists, use all attributes or if config exists, just use
      # existing attributes for user
      if attribute_list.blank? || attribute_list[key.to_s]
        user_related_changes[key] = value
      end
    end
    user_related_changes
  end

  def readable_changes(record, user_related_changes, attribute_list, locale)
    changes = {}
    user_related_changes.each do |key, value|
      is_relation_field = key.to_s.end_with?('_id')

      attribute_name = attribute_name(is_relation_field, key)

      if is_relation_field
        value = id_to_relation_value(record, attribute_name, value)
      end

      attribute = attribute_list&.dig(key.to_s)
      display = display_name(attribute) || attribute_name
      changes[display] = display_value(locale, value, attribute)
    end

    changes
  end

  def attribute_name(is_relation_field, key)
    attribute_name = key.to_s

    return attribute_name[0..-4] if is_relation_field

    attribute_name
  end

  def id_to_relation_value(record, attribute_name, value)
    relation_class = record.public_send(attribute_name)&.class
    value.map do |id|
      next id if !relation_class

      relation_model_visible_value(relation_class, id)
    end
  end

  def relation_model_visible_value(relation_class, id)
    relation_model = relation_class.lookup(id: id)
    return id.to_s if !relation_model

    return relation_model['name'] if relation_model['name']
    return relation_model.fullname if relation_model.respond_to?(:fullname)

    id
  end

  def display_name(attribute)
    return attribute[:display].to_s if attribute && attribute[:display]

    nil
  end

  def display_value(locale, value, attribute)
    if attribute && attribute[:translate]
      return [Translation.translate(locale, value[0]), Translation.translate(locale, value[1])]
    end

    [value[0].to_s, value[1].to_s]
  end

end

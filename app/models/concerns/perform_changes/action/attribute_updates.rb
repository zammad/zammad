# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::AttributeUpdates < PerformChanges::Action
  def self.phase
    :before_save
  end

  def execute(...)
    valid_attributes!

    execution_data.reduce(false) do |result, (key, value)|
      needs_saving = single_execution_block(key, value)
      result || needs_saving
    end
  end

  private

  def single_execution_block(key, value)
    case key
    when 'subscribe'
      subscribe(value)
    when 'unsubscribe'
      unsubscribe(value)
    when 'tags'
      tags(value)
    else
      object_attribute = object_manager_attribute(key)

      change_date(key, value, performable, object_attribute) || change_attribute(key, value, object_attribute)
    end
  end

  def change_attribute(key, value, object_attribute)
    exchange_user_id(value)
    template_value(value)

    update_key(key, value['value'], object_attribute)

    true
  end

  def valid_attributes!
    raise "The given #{origin} contains invalid attributes, stopping!" if execution_data.keys.any? { |key| !attribute_valid?(key) }

    true
  end

  def attribute_valid?(attribute)
    return true if %w[tags subscribe unsubscribe].include?(attribute)

    record.class.column_names.include?(attribute)
  end

  def update_key(attribute, value, object_attribute)
    return if record[attribute].to_s.eql?(value.to_s)

    if value.is_a?(String)
      value = value.strip

      # When only a string is given, but the attribute is multiple, we need to convert it to an array.
      value = [value] if object_attribute&.data_option&.fetch(:multiple, false)
    end

    record[attribute] = value
    history(attribute, value)
  end

  def tags(value)
    return if record.class.included_modules.exclude?(HasTags)

    tags = value['value'].split(',')
    return if tags.blank?

    operator = tags_operator(value)
    return if operator.blank?

    tags.each do |tag|
      record.send(:"tag_#{operator}", tag, user_id || 1, sourceable: performable)
    end

    nil
  end

  def tags_operator(value)
    operator = value['operator']

    if %w[add remove].exclude?(operator)
      Rails.logger.error "Unknown tags operator #{value['operator']}"
      return
    end

    operator
  end

  def subscribe(value)
    user = value['pre_condition'] == 'specific' ? User.find_by(id: value['value']) : User.find_by(id: user_id)

    # Ignore it for non-agent users.
    return if !Mention.mentionable?(record, user)

    Mention.subscribe! record, user, sourceable: performable

    nil
  end

  def unsubscribe(value)
    if value['pre_condition'] == 'specific'
      Mention.unsubscribe! record, User.find_by(id: value['value']), sourceable: performable
    elsif value['pre_condition'] == 'not_set'
      Mention.unsubscribe_all! record, sourceable: performable
    else
      Mention.unsubscribe! record, User.find_by(id: user_id), sourceable: performable
    end

    nil
  end

  def exchange_user_id(value)
    return if !value.key?('pre_condition')

    if value['pre_condition'].start_with?('not_set')
      value['value'] = 1
    elsif value['pre_condition'].start_with?('current_user.')
      # TODO: Check if we have all needed stuff in place (e.g. current_user.organization_id, but it was then also broken before)

      raise __("The required parameter 'user_id' is missing.") if !user_id

      value['value'] = user_id
    end

    true
  end

  def history(attribute, value)
    record.history_change_source_attribute(performable, attribute)
    Rails.logger.debug { "set #{record.class.name.downcase}.#{attribute} = #{value.inspect} for #{record.class.name} with id #{record.id}" }
  end

  def change_date(attribute, value, performable, object_attribute)
    return if object_attribute.blank? || %w[datetime date].exclude?(object_attribute[:data_type])

    new_value = fetch_new_date_value(value)
    return if !new_value

    record[attribute] = format_new_date_value(new_value, object_attribute)

    record.history_change_source_attribute(performable, attribute)

    true
  end

  def object_manager_attribute(attribute)
    ObjectManager::Attribute.for_object(record.class.name).find_by(name: attribute)
  end

  def fetch_new_date_value(value)
    case value['operator']
    when 'relative'
      # Clear seconds & miliseconds
      # Because time picker allows to put in hours and minutes only
      # If time contains seconds, detection of changed input malfunctions
      TimeRangeHelper
        .relative(range: value['range'], value: value['value'])
        .change(usec: 0, sec: 0)
    else
      value['value']
    end
  end

  def format_new_date_value(new_value, object_attribute)
    case object_attribute[:data_type]
    when 'datetime'
      new_value.to_datetime
    else
      new_value.to_date
    end
  end

  def template_value(value)
    return value if !value['value'].is_a?(String)

    value['value'] = NotificationFactory::Mailer.template(
      templateInline: value['value'],
      objects:        notification_factory_template_objects,
      quote:          false,
      locale:         locale,
      timezone:       timezone,
    )

    true
  end
end

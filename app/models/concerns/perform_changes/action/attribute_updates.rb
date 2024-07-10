# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::AttributeUpdates < PerformChanges::Action
  def execute(...)
    valid_attributes!

    execution_data.each do |key, value|
      next if key.eql?('subscribe') && subscribe(value)
      next if key.eql?('unsubscribe') && unsubscribe(value)
      next if key.eql?('tags') && tags(value)
      next if change_date(key, value, performable)

      exchange_user_id(value)
      template_value(value)

      update_key(key, value['value'])
    end
  end

  private

  def valid_attributes!
    raise "The given #{origin} contains invalid attributes, stopping!" if execution_data.keys.any? { |key| !attribute_valid?(key) }

    true
  end

  def attribute_valid?(attribute)
    return true if %w[tags subscribe unsubscribe].include?(attribute)

    record.class.column_names.include?(attribute)
  end

  def update_key(attribute, value)
    return if record[attribute].to_s.eql?(value.to_s)

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

    true
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
    if value['pre_condition'] == 'specific'
      Mention.subscribe! record, User.find_by(id: value['value'])
    else
      Mention.subscribe! record, User.find_by(id: user_id)
    end
  end

  def unsubscribe(value)
    if value['pre_condition'] == 'specific'
      Mention.unsubscribe! record, User.find_by(id: value['value'])
    elsif value['pre_condition'] == 'not_set'
      Mention.unsubscribe_all! record
    else
      Mention.unsubscribe! record, User.find_by(id: user_id)
    end
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

  def change_date(attribute, value, performable)
    oa = object_manager_attribute(attribute)
    return if oa.blank?

    new_value = fetch_new_date_value(value)
    return if !new_value

    record[attribute] = format_new_date_value(new_value, oa)

    record.history_change_source_attribute(performable, attribute)

    true
  end

  def object_manager_attribute(attribute)
    ObjectManager::Attribute.for_object(record.class.name).find_by(name: attribute, data_type: %w[datetime date])
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

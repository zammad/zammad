# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::Date < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_type == 'date'
  end

  def map_value(field:, config:)
    result[field][:value] = resolve_time(config:)
  end

  protected

  def resolve_time(config:)
    if config['operator'] != 'relative'
      return config['value']
    end

    format_time TimeRangeHelper.relative(range: config['range'], value: config['value'])
  end

  def format_time(time)
    time.strftime('%Y-%m-%d')
  end
end

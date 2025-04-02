# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::Datetime < FormUpdater::ApplyValue::Date

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_type == 'datetime'
  end

  def format_time(time)
    time.iso8601
  end
end

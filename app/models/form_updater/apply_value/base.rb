# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::Base

  attr_reader :context, :data, :dirty_fields, :result

  def initialize(context:, data:, dirty_fields:, result:)
    @context = context
    @data    = data
    @dirty_fields = dirty_fields
    @result = result
  end

  def can_handle_field?(field:, field_attribute:)
    false
  end

  def apply_value(field:, config:)
    return if skip_dirty_field?(field:)

    map_value(field:, config:)
  end

  def skip_dirty_field?(field:)
    dirty_fields&.include?(field) && data[field].present?
  end
end

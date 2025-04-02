# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::StoreValue::Multiple < FormUpdater::StoreValue::Base

  def can_handle_field?(field:, value:)
    multiple_fields.include? field
  end

  def map_value(field:, value:)
    return '' if !value.is_a?(Array)

    value.join(', ')
  end

  def multiple_fields
    %w[
      to
      cc
      tags
    ]
  end
end

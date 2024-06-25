# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::RecipientAutocomplete < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field == 'cc'
  end

  def map_value(field:, config:)
    user = ::User.search(
      query:        config['value'],
      limit:        1,
      current_user: context[:current_user],
    )

    value   = config['value']
    label   = value
    heading = nil

    if user.present?
      value  = user.first.email
      label  = user.first.email
      heading = user.first.fullname
    end

    result[field][:value] = Array(value)
    result[field][:options] = [{
      value:   value,
      label:   label,
      heading: heading,
    }]
  end
end

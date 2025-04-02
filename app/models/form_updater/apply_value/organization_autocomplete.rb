# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::OrganizationAutocomplete < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_option&.[]('relation') == 'Organization'
  end

  def map_value(field:, config:)
    org = Organization.find_by(id: config['value'])
    return if !org

    result[field][:value] = org.id
    result[field][:options] = [{
      value: org.id,
      label: org.name,
    }]
  end
end

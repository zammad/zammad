# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::UserAutocomplete < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_option&.[]('relation') == 'User'
  end

  def map_value(field:, config:)
    user = User.find_by(id: config['value'])
    return if !user

    user_obj = user.attributes
      .slice('active', 'email', 'firstname', 'fullname', 'image', 'lastname', 'mobile', 'out_of_office', 'out_of_office_end_at', 'out_of_office_start_at', 'phone', 'source', 'vip')
      .merge({
               '__typename' => 'User',
               'id'         => Gql::ZammadSchema.id_from_internal_id('User', user.id),
             })

    result[field][:value] = user.id
    result[field][:options] = [{
      value:   user.id,
      label:   user.fullname.presence || user.phone.presence || user.login,
      heading: user.organization&.name,
      object:  user_obj,
    }]
  end
end

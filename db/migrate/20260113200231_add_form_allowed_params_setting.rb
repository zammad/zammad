# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddFormAllowedParamsSetting < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Form Allowed Parameters',
      name:        'form_allowed_params',
      area:        'Form::API',
      description: 'Defines which parameters are allowed to be submitted via the form API.',
      state:       [],
      frontend:    false
    )
  end
end

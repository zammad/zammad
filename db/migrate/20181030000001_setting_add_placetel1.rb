# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingAddPlacetel1 < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Placetel integration',
      name:        'placetel_integration',
      area:        'Integration::Switch',
      description: 'Defines if Placetel (http://www.placetel.de) is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'placetel_integration',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:           1,
        trigger:        ['menu:render', 'cti:reload'],
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true
    )
    placetel_config = Setting.find_by(name: 'placetel_config')
    if placetel_config
      placetel_config.preferences[:cache] = ['placetelGetVoipUsers']
      placetel_config.save!
    else
      Setting.create!(
        title:       'Placetel config',
        name:        'placetel_config',
        area:        'Integration::Placetel',
        description: 'Defines the Placetel config.',
        options:     {},
        state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
        preferences: {
          prio:       2,
          permission: ['admin.integration'],
          cache:      ['placetelGetVoipUsers'],
        },
        frontend:    false,
      )
    end
    Setting.create_if_not_exists(
      title:       'PLACETEL Token',
      name:        'placetel_token',
      area:        'Integration::Placetel',
      description: 'Token for placetel.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'placetel_token',
            tag:     'input',
          },
        ],
      },
      state:       ENV['PLACETEL_TOKEN'] || SecureRandom.urlsafe_base64(20),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend:    false
    )
  end
end

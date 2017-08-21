class CheckMkIntegration < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title: 'Check_MK integration',
      name: 'check_mk_integration',
      area: 'Integration::Switch',
      description: 'Defines if Check_MK (http://mathias-kettner.com/check_mk.html) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'check_mk_integration',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      preferences: {
        prio: 1,
        permission: ['admin.integration'],
      },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Group',
      name: 'check_mk_group_id',
      area: 'Integration::CheckMK',
      description: 'Defines the group of created tickets.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'check_mk_group_id',
            tag: 'select',
            relation: 'Group',
          },
        ],
      },
      state: 1,
      preferences: {
        prio: 2,
        permission: ['admin.integration'],
      },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Auto close',
      name: 'check_mk_auto_close',
      area: 'Integration::CheckMK',
      description: 'Defines if tickets should be closed if service is recovered.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'check_mk_auto_close',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      preferences: {
        prio: 3,
        permission: ['admin.integration'],
      },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Auto close state',
      name: 'check_mk_auto_close_state_id',
      area: 'Integration::CheckMK',
      description: 'Defines the state of auto closed tickets.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'check_mk_auto_close_state_id',
            tag: 'select',
            relation: 'TicketState',
          },
        ],
      },
      state: 4,
      preferences: {
        prio: 4,
        permission: ['admin.integration'],
      },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Check_MK tolen',
      name: 'check_mk_token',
      area: 'Core',
      description: 'Defines the Check_MK token for allowing updates.',
      options: {},
      state: SecureRandom.hex(16),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend: false
    )
  end

end

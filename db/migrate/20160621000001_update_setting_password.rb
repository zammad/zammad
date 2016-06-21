class UpdateSettingPassword < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_or_update(
      title: 'Ignore Escalation/SLA Information',
      name: 'import_ignore_sla',
      area: 'Import::Base',
      description: 'Ignore Escalation/SLA Information form import system.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'import_ignore_sla',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      frontend: false,
    )
    Setting.create_or_update(
      title: 'Define searchable models.',
      name: 'models_searchable',
      area: 'Models::Base',
      description: 'Define the models which can be searched for.',
      options: {},
      state: [],
      frontend: true,
    )
    Setting.create_or_update(
      title: 'Minimal size',
      name: 'password_min_size',
      area: 'Security::Password',
      description: 'Password need to have at least minimal size of characters.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'password_min_size',
            tag: 'select',
            options: {
              4 => ' 4',
              5 => ' 5',
              6 => ' 6',
              7 => ' 7',
              8 => ' 8',
              9 => ' 9',
              10 => '10',
              11 => '11',
              12 => '12',
              13 => '13',
              14 => '14',
              15 => '15',
              16 => '16',
              17 => '17',
              18 => '18',
              19 => '19',
              20 => '20',
            },
          },
        ],
      },
      state: 6,
      frontend: false,
    )
    Setting.create_or_update(
      title: '2 lower and 2 upper characters',
      name: 'password_min_2_lower_2_upper_characters',
      area: 'Security::Password',
      description: 'Password need to contain 2 lower and 2 upper characters.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'password_min_2_lower_2_upper_characters',
            tag: 'select',
            options: {
              1 => 'yes',
              0 => 'no',
            },
          },
        ],
      },
      state: 0,
      frontend: false,
    )
    Setting.create_or_update(
      title: 'Digit required',
      name: 'password_need_digit',
      area: 'Security::Password',
      description: 'Password need to have at least one digit.',
      options: {
        form: [
          {
            display: 'Needed',
            null: true,
            name: 'password_need_digit',
            tag: 'select',
            options: {
              1 => 'yes',
              0 => 'no',
            },
          },
        ],
      },
      state: 1,
      frontend: false,
    )
    Setting.create_or_update(
      title: 'Maximal failed logins',
      name: 'password_max_login_failed',
      area: 'Security::Password',
      description: 'Maximal failed logins after account is inactive.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'password_max_login_failed',
            tag: 'select',
            options: {
              4 => ' 4',
              5 => ' 5',
              6 => ' 6',
              7 => ' 7',
              8 => ' 8',
              9 => ' 9',
              10 => '10',
              11 => '11',
              13 => '13',
              14 => '14',
              15 => '15',
              16 => '16',
              17 => '17',
              18 => '18',
              19 => '19',
              20 => '20',
            },
          },
        ],
      },
      state: 10,
      frontend: false,
    )
  end
end

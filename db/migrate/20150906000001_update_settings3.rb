class UpdateSettings3 < ActiveRecord::Migration
  def up
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
      frontend: true
    )
    Setting.create_or_update(
      title: 'Max. Email Size',
      name: 'postmaster_max_size',
      area: 'Email::Base',
      description: 'Maximal size in MB of emails.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'postmaster_max_size',
            tag: 'select',
            options: {
              1 => '  1',
              2 => '  2',
              3 => '  3',
              4 => '  4',
              5 => '  5',
              6 => '  6',
              7 => '  7',
              8 => '  8',
              9 => '  9',
              10 => ' 10',
              15 => ' 15',
              20 => ' 20',
              25 => ' 25',
              30 => ' 30',
              35 => ' 35',
              40 => ' 40',
              45 => ' 45',
              50 => ' 50',
              60 => ' 60',
              70 => ' 70',
              80 => ' 80',
              90 => ' 90',
              100 => '100',
              125 => '125',
              150 => '150',
            },
          },
        ],
      },
      state: 10,
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Ticket Number Increment',
      name: 'ticket_number_increment',
      area: 'Ticket::Number',
      description: '-',
      options: {
        form: [
          {
            display: 'Checksum',
            null: true,
            name: 'checksum',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
          {
            display: 'Min. size of number',
            null: true,
            name: 'min_size',
            tag: 'select',
            options: {
              1 => ' 1',
              2 => ' 2',
              3 => ' 3',
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
      state: {
        checksum: false,
        min_size: 5,
      },
      frontend: false
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
      frontend: true
    )

    options = {}
    (10..99).each {|item|
      options[item] = item
    }
    system_id = rand(10..99)
    current = Setting.find_by(name: 'system_id')
    if current
      system_id = Setting.get('system_id')
    end
    Setting.create_or_update(
      title: 'SystemID',
      name: 'system_id',
      area: 'System::Base',
      description: 'Defines the system identifier. Every ticket number contains this ID. This ensures that only tickets which belong to your system will be processed as follow-ups (useful when communicating between two instances of Zammad).',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'system_id',
            tag: 'select',
            options: options,
          },
        ],
      },
      state: system_id,
      preferences: { online_service_disable: true },
      frontend: true
    )

  end
end

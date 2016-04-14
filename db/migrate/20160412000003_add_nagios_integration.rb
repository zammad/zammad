class AddNagiosIntegration < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '5100_postmaster_filter_nagios',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter for manage Nagios (http://www.nagios.org) emails.',
      options: {},
      state: 'Channel::Filter::Nagios',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Nagios integration',
      name: 'nagios_integration',
      area: 'Integration::Nagios',
      description: 'Define if Nagios (http://www.nagios.org) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'nagios_integration',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      preferences: { prio: 1 },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Sender',
      name: 'nagios_sender',
      area: 'Integration::Nagios',
      description: 'Define the sender email address of Nagios emails.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'nagios_sender',
            tag: 'input',
          },
        ],
      },
      state: 'nagios@monitoring.example.com',
      frontend: false,
      preferences: { prio: 2 },
    )
    Setting.create_if_not_exists(
      title: 'Auto close',
      name: 'nagios_auto_close',
      area: 'Integration::Nagios',
      description: 'Define if tickets should be closed if service is recovered.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'nagios_auto_close',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      preferences: { prio: 3 },
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Auto close state',
      name: 'nagios_auto_close_state_id',
      area: 'Integration::Nagios',
      description: 'Define the ticket state of auto closed tickets.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'nagios_auto_close_state_id',
            tag: 'select',
            relation: 'TicketState',
          },
        ],
      },
      state: 4,
      preferences: { prio: 4 },
      frontend: false
    )
  end
end

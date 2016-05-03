class AddSlackIntegration < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Icinga integration',
      name: 'icinga_integration',
      area: 'Integration::Switch',
      description: 'Define if Icinga (http://www.icinga.org) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'icinga_integration',
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
    Setting.create_or_update(
      title: 'Sender',
      name: 'icinga_sender',
      area: 'Integration::Icinga',
      description: 'Define the sender email address of Icinga emails.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'icinga_sender',
            tag: 'input',
            placeholder: 'icinga@monitoring.example.com',
          },
        ],
      },
      state: 'icinga@monitoring.example.com',
      frontend: false,
      preferences: { prio: 2 },
    )
    Setting.create_or_update(
      title: 'Nagios integration',
      name: 'nagios_integration',
      area: 'Integration::Switch',
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
    Setting.create_or_update(
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
            placeholder: 'nagios@monitoring.example.com',
          },
        ],
      },
      state: 'nagios@monitoring.example.com',
      frontend: false,
      preferences: { prio: 2 },
    )

    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '0100_notification',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend to send agent notifications.',
      options: {},
      state: 'Transaction::Notification',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '6000_slack_webhook',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend which posts messages to (http://www.slack.com).',
      options: {},
      state: 'Transaction::Slack',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Slack integration',
      name: 'slack_integration',
      area: 'Integration::Slack',
      description: 'Define if Slack (http://www.slack.org) is enabled or not.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'slack_integration',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      preferences: { prio: 1 },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Slack config',
      name: 'slack_config',
      area: 'Integration::Slack',
      description: 'Define the slack config.',
      options: {},
      state: {
        items: []
      },
      frontend: false,
      preferences: { prio: 2 },
    )
  end
end

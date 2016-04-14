class AddIchingaIntegration < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0015_postmaster_filter_identify_sender',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to identify sender user.',
      options: {},
      state: 'Channel::Filter::IdentifySender',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0020_postmaster_filter_auto_response_check',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to identify auto responses to prevent auto replies from Zammad.',
      options: {},
      state: 'Channel::Filter::AutoResponseCheck',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0030_postmaster_filter_out_of_office_check',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to identify out of office emails for follow up detection and keeping current ticket state.',
      options: {},
      state: 'Channel::Filter::OutOfOfficeCheck',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0100_postmaster_filter_follow_up_check',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to identify follow ups (based on admin settings).',
      options: {},
      state: 'Channel::Filter::FollowUpCheck',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0900_postmaster_filter_bounce_check',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to identify postmaster bounced - to handle it as follow up of origin ticket.',
      options: {},
      state: 'Channel::Filter::BounceCheck',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '1000_postmaster_filter_database_check',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter for filters managed via admin interface.',
      options: {},
      state: 'Channel::Filter::Database',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '5000_postmaster_filter_icinga',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter for manage Icinga (http://www.icinga.org) emails.',
      options: {},
      state: 'Channel::Filter::Icinga',
      frontend: false
    )
    Setting.create_if_not_exists(
      title: 'Icinga integration',
      name: 'icinga_integration',
      area: 'Integration::Icinga',
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
    Setting.create_if_not_exists(
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
          },
        ],
      },
      state: 'icinga@monitoring.example.com',
      frontend: false,
      preferences: { prio: 2 },
    )
    Setting.create_if_not_exists(
      title: 'Auto close',
      name: 'icinga_auto_close',
      area: 'Integration::Icinga',
      description: 'Define if tickets should be closed if service is recovered.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'icinga_auto_close',
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
      name: 'icinga_auto_close_state_id',
      area: 'Integration::Icinga',
      description: 'Define the ticket state of auto closed tickets.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'icinga_auto_close_state_id',
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

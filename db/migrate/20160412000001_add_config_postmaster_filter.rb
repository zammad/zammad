class AddConfigPostmasterFilter < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0010_postmaster_filter_trusted',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to remove X-Zammad-Headers from not trusted sources.',
      options: {},
      state: 'Channel::Filter::Trusted',
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

  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6342DashboardSettings, type: :db_migration do
  let(:setting_names) do
    %w[
      dashboard dashboard_activity_stream dashboard_activity_stream_own dashboard_first_steps
      dashboard_stats_ticket_waiting_time dashboard_stats_ticket_escalation dashboard_stats_ticket_channel_distribution
      dashboard_stats_ticket_load_measure dashboard_stats_ticket_in_process dashboard_stats_ticket_reopen
    ]
  end

  before do
    Setting.where(name: setting_names).destroy_all
    Permission.find_by(name: 'admin.dashboard')&.destroy

    migrate
  end

  it 'adds the settings, only the limit to own activities turned off' do
    values = Setting.where(name: setting_names).to_h { |setting| [setting.name, setting.state_current[:value]] }

    expect(values).to eq(
      'dashboard'                                   => true,
      'dashboard_activity_stream'                   => true,
      'dashboard_activity_stream_own'               => false,
      'dashboard_first_steps'                       => true,
      'dashboard_stats_ticket_waiting_time'         => true,
      'dashboard_stats_ticket_escalation'           => true,
      'dashboard_stats_ticket_channel_distribution' => true,
      'dashboard_stats_ticket_load_measure'         => true,
      'dashboard_stats_ticket_in_process'           => true,
      'dashboard_stats_ticket_reopen'               => true,
    )
  end

  it 'adds the permission' do
    expect(Permission).to exist(name: 'admin.dashboard')
  end
end

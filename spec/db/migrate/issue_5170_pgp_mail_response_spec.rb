# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5170PGPMailResponse, type: :db_migration do
  before do
    Setting
      .where(area: 'Postmaster::PreFilter')
      .find { |elem| elem.state_current[:value] == 'Channel::Filter::SecureMailing' }
      .update!(name: '0016_postmaster_filter_secure_mailing')

    Setting
      .where(area: 'Postmaster::PreFilter')
      .find { |elem| elem.state_current[:value] == 'Channel::Filter::Trusted' }
      .update!(name: '0005_postmaster_filter_trusted')
  end

  it 'moves trusted prefilter to front of the queue' do
    expect { migrate }
      .not_to change { Setting.where(area: 'Postmaster::PreFilter').reorder(:name).first.state_current[:value] }
      .from('Channel::Filter::Trusted')
  end

  it 'moves PGP prefilter to second of the queue' do
    expect { migrate }
      .to change { Setting.where(area: 'Postmaster::PreFilter').reorder(:name).second.state_current[:value] }
      .to('Channel::Filter::SecureMailing')
  end
end

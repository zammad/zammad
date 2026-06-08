# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChannelConcurrencyChanges, type: :db_migration do
  let(:scheduled_job) { Scheduler.find_by(method: 'Channel.fetch_async') }

  before do
    scheduled_job
      .update!(method: 'Channel.fetch')
  end

  it 'updates Channel.fetch to Channel.fetch_async in Sheduler' do
    expect { migrate }
      .to change { scheduled_job.reload.method }
      .to('Channel.fetch_async')
  end
end

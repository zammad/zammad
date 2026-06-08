# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChannelFetchJob, type: :job do
  let(:channel) { create(:email_channel) }

  it 'calls fetch on a given channel' do
    allow(channel).to receive(:fetch)

    described_class.perform_now(channel)

    expect(channel).to have_received(:fetch)
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3964InboundFixOptions, type: :db_migration do
  let(:channel1) { create(:google_channel) }
  let(:channel2) { create(:google_channel) }

  before do
    channel1.options[:inbound][:options][:ssl] = true
    channel1.save
    channel2.options[:inbound][:options][:ssl] = false
    channel2.save
    migrate
  end

  it 'sets the correct ssl value for ssl true' do
    expect(channel1.reload.options[:inbound][:options][:ssl]).to eq('ssl')
  end

  it 'sets the correct ssl value for ssl false' do
    expect(channel2.reload.options[:inbound][:options][:ssl]).to eq('off')
  end
end

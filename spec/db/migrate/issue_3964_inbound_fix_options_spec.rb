# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3964InboundFixOptions, type: :db_migration do
  let(:channel) do
    build(:google_channel)
      .tap { _1.options[:inbound][:options][:ssl] = old_value }
      .tap(&:save!)
  end

  before do
    channel
    migrate
  end

  context 'when old value is true' do
    let(:old_value) { true }

    it 'sets the correct ssl value for ssl true' do
      expect(channel.reload.options[:inbound][:options][:ssl]).to eq('ssl')
    end
  end

  context 'when old value is false' do
    let(:old_value) { false }

    it 'sets the correct ssl value for ssl false' do
      expect(channel.reload.options[:inbound][:options][:ssl]).to eq('off')
    end
  end
end

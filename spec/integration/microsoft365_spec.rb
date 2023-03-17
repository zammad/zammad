# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
RSpec.describe 'Microsoft365 XOAUTH2', integration: true, required_envs: %w[MICROSOFT365_REFRESH_TOKEN MICROSOFT365_CLIENT_ID MICROSOFT365_CLIENT_SECRET MICROSOFT365_USER] do # rubocop:disable RSpec/DescribeClass
  let(:channel) do
    create(:microsoft365_channel).tap(&:refresh_xoauth2!)
  end

  context 'when probing inbound' do
    before do
      options = channel.options[:inbound][:options]
      options[:port] = 993

      imap_delete_old_mails(options)
    end

    it 'succeeds' do
      result = EmailHelper::Probe.inbound(channel.options[:inbound])
      expect(result[:result]).to eq('ok')
    end
  end

  context 'when probing outbound' do
    it 'succeeds' do
      result = EmailHelper::Probe.outbound(channel.options[:outbound], ENV['MICROSOFT365_USER'], "test microsoft365 oauth unittest #{Random.new_seed}")
      expect(result[:result]).to eq('ok')
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
RSpec.describe 'Gmail XOAUTH2', integration: true, required_envs: %w[GMAIL_REFRESH_TOKEN GMAIL_CLIENT_ID GMAIL_CLIENT_SECRET GMAIL_USER] do # rubocop:disable RSpec/DescribeClass
  let(:channel) do
    create(:google_channel).tap(&:refresh_xoauth2!)
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
      result = EmailHelper::Probe.outbound(channel.options[:outbound], ENV['GMAIL_USER'], "test gmail oauth unittest #{Random.new_seed}")
      expect(result[:result]).to eq('ok')
    end
  end
end

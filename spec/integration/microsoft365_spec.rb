# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
RSpec.describe 'Microsoft365 XOAUTH2', type: :integration do # rubocop:disable RSpec/DescribeClass
  let(:channel) do
    create(:microsoft365_channel).tap(&:refresh_xoauth2!)
  end

  before do
    required_envs = %w[MICROSOFT365_REFRESH_TOKEN MICROSOFT365_CLIENT_ID MICROSOFT365_CLIENT_SECRET MICROSOFT365_USER]
    required_envs.each do |key|
      skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
    end
  end

  context 'when probing inbound' do
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

require 'rails_helper'
RSpec.describe 'Microsoft365 XOAUTH2' do # rubocop:disable RSpec/DescribeClass
  let(:channel) { create(:microsoft365_channel) }

  before do
    required_envs = %w[MICROSOFT365_REFRESH_TOKEN MICROSOFT365_CLIENT_ID MICROSOFT365_CLIENT_SECRET MICROSOFT365_USER]
    required_envs.each do |key|
      skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
    end
  end

  context 'inbound' do
    it 'succeeds' do
      result = EmailHelper::Probe.inbound(channel.options[:inbound])
      expect(result[:result]).to eq('ok')
    end
  end

  context 'outbound' do
    it 'succeeds' do
      result = EmailHelper::Probe.outbound(channel.options[:outbound], ENV['MICROSOFT365_USER'], "test microsoft365 oauth unittest #{Random.new_seed}")
      expect(result[:result]).to eq('ok')
    end
  end
end

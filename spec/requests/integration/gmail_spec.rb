require 'rails_helper'
RSpec.describe 'Gmail XOAUTH2' do # rubocop:disable RSpec/DescribeClass
  let(:channel) { create(:google_channel) }

  before do
    required_envs = %w[GMAIL_REFRESH_TOKEN GMAIL_CLIENT_ID GMAIL_CLIENT_SECRET GMAIL_USER]
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
      result = EmailHelper::Probe.outbound(channel.options[:outbound], ENV['GMAIL_USER'], "test gmail oauth unittest #{Random.new_seed}")
      expect(result[:result]).to eq('ok')
    end
  end
end

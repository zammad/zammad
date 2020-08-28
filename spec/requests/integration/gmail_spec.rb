require 'rails_helper'
RSpec.describe 'Gmail XOAUTH2' do # rubocop:disable RSpec/DescribeClass
  let(:channel) do
    create(:channel,
           area:    'Google::Account',
           options: {
             'inbound'  => {
               'adapter' => 'imap',
               'options' => {
                 'auth_type'      => 'XOAUTH2',
                 'host'           => 'imap.gmail.com',
                 'ssl'            => true,
                 'user'           => ENV['GMAIL_USER'],
                 'folder'         => '',
                 'keep_on_server' => false,
               }
             },
             'outbound' => {
               'adapter' => 'smtp',
               'options' => {
                 'host'           => 'smtp.gmail.com',
                 'domain'         => 'gmail.com',
                 'port'           => 465,
                 'ssl'            => true,
                 'user'           => ENV['GMAIL_USER'],
                 'authentication' => 'xoauth2',
               }
             },
             'auth'     => {
               'type'          => 'XOAUTH2',
               'provider'      => 'google',
               'access_token'  => 'xxx',
               'expires_in'    => 3599,
               'refresh_token' => ENV['GMAIL_REFRESH_TOKEN'],
               'scope'         => 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://mail.google.com/ openid',
               'token_type'    => 'Bearer',
               'id_token'      => 'xxx',
               'created_at'    => 30.days.ago,
               'client_id'     => ENV['GMAIL_CLIENT_ID'],
               'client_secret' => ENV['GMAIL_CLIENT_SECRET'],
             }
           })
  end

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

  context 'when non-Google channels are present' do

    let!(:email_address) { create(:email_address, channel: create(:channel, area: 'Some::Other')) }

    before do
      channel
    end

    it "doesn't remove email address assignments" do
      expect { Channel.where(area: 'Google::Account').find_each {} }.not_to change { email_address.reload.channel_id }
    end
  end
end

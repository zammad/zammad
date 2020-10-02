require 'rails_helper'
RSpec.describe 'Office365 XOAUTH2' do # rubocop:disable RSpec/DescribeClass
  let(:channel) do
    create(:channel,
           area:    'Office365::Account',
           options: {
             'inbound'  => {
               'adapter' => 'imap',
               'options' => {
                 'auth_type'      => 'XOAUTH2',
                 'host'           => 'outlook.office365.com',
                 'ssl'            => true,
                 'user'           => ENV['OFFICE365_USER'],
                 'folder'         => '',
                 'keep_on_server' => false,
               }
             },
             'outbound' => {
               'adapter' => 'smtp',
               'options' => {
                 'host'           => 'smtp.office365.com',
                 'domain'         => 'office365.com',
                 'port'           => 587,
                 'user'           => ENV['OFFICE365_USER'],
                 'authentication' => 'xoauth2',
               }
             },
             'auth'     => {
               'type'          => 'XOAUTH2',
               'provider'      => 'office365',
               'access_token'  => 'xxx',
               'expires_in'    => 3599,
               'refresh_token' => ENV['OFFICE365_REFRESH_TOKEN'],
               'scope'         => 'https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access openid profile email',
               'token_type'    => 'Bearer',
               'id_token'      => 'xxx',
               'created_at'    => 30.days.ago,
               'client_id'     => ENV['OFFICE365_CLIENT_ID'],
               'client_secret' => ENV['OFFICE365_CLIENT_SECRET'],
             }
           })
  end

  before do
    required_envs = %w[OFFICE365_REFRESH_TOKEN OFFICE365_CLIENT_ID OFFICE365_CLIENT_SECRET OFFICE365_USER]
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
      result = EmailHelper::Probe.outbound(channel.options[:outbound], ENV['OFFICE365_USER'], "test office365 oauth unittest #{Random.new_seed}")
      expect(result[:result]).to eq('ok')
    end
  end

  context 'when non-Office365 channels are present' do

    let!(:email_address) { create(:email_address, channel: create(:channel, area: 'Some::Other')) }

    before do
      channel
    end

    it "doesn't remove email address assignments" do
      expect { Channel.where(area: 'Office365::Account').find_each {} }.not_to change { email_address.reload.channel_id }
    end
  end
end

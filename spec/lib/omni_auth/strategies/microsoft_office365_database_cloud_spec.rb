# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::MicrosoftOffice365Database, :aggregate_failures do
  let(:graph_hosts) { { 'global' => 'graph.microsoft.com', 'us_gov' => 'graph.microsoft.us' } }

  %w[global us_gov].each do |cloud|
    context "with #{cloud} cloud" do
      subject(:strategy) { described_class.new(nil) }

      let(:login_host)   { cloud == 'global' ? 'login.microsoftonline.com' : 'login.microsoftonline.us' }
      let(:graph_host)   { graph_hosts.fetch(cloud) }
      let(:access_token) { instance_double(OAuth2::AccessToken) }

      before do
        Setting.set('auth_microsoft_office365_credentials', { app_id: 'client', app_secret: 'secret', app_tenant: 'tenant', cloud: cloud })
      end

      it 'uses the same cloud for sign-in, token exchange and Graph scopes' do
        expect(strategy.options[:client_options][:site]).to eq("https://#{login_host}")
        expect(strategy.options[:client_options][:authorize_url]).to eq('/tenant/oauth2/v2.0/authorize')
        expect(strategy.options[:client_options][:token_url]).to eq('/tenant/oauth2/v2.0/token')
        scope = cloud == 'global' ? 'User.Read' : "https://#{graph_host}/User.Read"
        expect(strategy.options[:scope]).to eq("openid #{scope}")
      end

      it 'keeps ID token claims alongside the national-cloud profile' do
        strategy.access_token = access_token
        profile = instance_double(OAuth2::Response, parsed: { 'id' => 'user' })
        allow(access_token).to receive(:get).with("https://#{graph_host}/v1.0/me").and_return(profile)
        allow(access_token).to receive(:params).and_return({ 'id_token' => JWT.encode({ 'xms_edov' => true }, nil, 'none') })

        expect(strategy.extra).to include('raw_info' => { 'id' => 'user' }, 'id_token_claims' => include('xms_edov' => true))
      end

      it 'allows a missing avatar without hiding other OAuth errors' do
        strategy.access_token = access_token
        missing = instance_double(OAuth2::Response, status: 404, parsed: {}, body: '')
        denied = instance_double(OAuth2::Response, status: 403, parsed: { 'error' => 'access_denied' }, body: 'Denied')
        allow(access_token).to receive(:get).with("https://#{graph_host}/v1.0/me/photo/$value").and_raise(OAuth2::Error.new(missing))
        expect(strategy.send(:avatar_file)).to be_nil

        allow(access_token).to receive(:get).with("https://#{graph_host}/v1.0/me/photo/$value").and_raise(OAuth2::Error.new(denied))
        expect { strategy.send(:avatar_file) }.to raise_error(OAuth2::Error)
      end

      it 'fetches profile and avatar through the gem info and uid blocks in that cloud' do
        strategy.access_token = access_token
        profile = instance_double(OAuth2::Response, parsed: { 'id' => 'user' })
        photo = instance_double(OAuth2::Response, content_type: 'image/jpeg', body: 'photo')
        allow(access_token).to receive(:get).with("https://#{graph_host}/v1.0/me").and_return(profile)
        allow(access_token).to receive(:get).with("https://#{graph_host}/v1.0/me/photo/$value").and_return(photo)

        expect(strategy.uid).to eq('user')
        avatar = strategy.info[:image]
        expect(avatar.read).to eq('photo')
        expect(File.extname(avatar.path)).to eq('.jpeg')
      ensure
        avatar&.close!
      end
    end
  end

  it 'defaults existing credentials to Global and the common tenant' do
    Setting.set('auth_microsoft_office365_credentials', { app_id: 'client', app_secret: 'secret' })
    strategy = described_class.new(nil)
    expect(strategy.options[:client_options][:site]).to eq('https://login.microsoftonline.com')
    expect(strategy.options[:client_options][:authorize_url]).to eq('/common/oauth2/v2.0/authorize')
    expect(strategy.options[:scope]).to eq('openid User.Read')
  end

  context 'with an invalid stored cloud' do
    before do
      allow(Setting).to receive(:get).with('auth_microsoft_office365_credentials').and_return({ 'cloud' => 'custom' })
    end

    it 'allows unrelated application requests through the middleware' do
      app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }
      strategy = described_class.new(app)

      response = Rack::MockRequest.new(strategy).get('/health', 'rack.session' => {})

      expect(response.status).to eq(200)
      expect(response.body).to eq('ok')
    end

    %i[request_phase callback_phase].each do |phase|
      it "fails #{phase} before making an OAuth request" do
        strategy = described_class.new(nil)
        allow(strategy).to receive(:fail!).with(:invalid_cloud, kind_of(ArgumentError)).and_return([302, {}, []])
        allow(strategy).to receive(:client)

        expect(strategy.public_send(phase)).to eq([302, {}, []])
        expect(strategy).not_to have_received(:client)
      end
    end
  end
end

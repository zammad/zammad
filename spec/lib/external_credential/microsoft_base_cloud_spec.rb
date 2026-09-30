# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::MicrosoftBase, :aggregate_failures do
  clouds = %w[global us_gov]
  let(:graph_resources) { { 'global' => '', 'us_gov' => 'https://graph.microsoft.us/' } }
  let(:mail_hosts) do
    {
      'global' => %w[outlook.office365.com smtp.office365.com],
      'us_gov' => %w[outlook.office365.us outlook.office365.us],
    }
  end

  [ExternalCredential::MicrosoftGraph, ExternalCredential::Microsoft365].each do |provider|
    context "with #{provider.provider_name}" do
      let(:credentials) { { client_id: 'client', client_secret: 'secret', client_tenant: 'tenant' } }

      clouds.each do |cloud|
        context "with #{cloud} cloud" do
          let(:cloud_credentials) { credentials.merge(cloud: cloud) }
          let(:login_host)        { cloud == 'global' ? 'login.microsoftonline.com' : 'login.microsoftonline.us' }
          let(:token_url)         { "https://#{login_host}/tenant/oauth2/v2.0/token" }
          let(:token_response) do
            {
              access_token: 'access', refresh_token: 'refresh', expires_in: 3600,
              scope: 'scope', token_type: 'Bearer',
              id_token: JWT.encode({ preferred_username: 'user@example.com' }, nil, 'none'),
            }
          end

          before do
            create(:external_credential, name: provider.provider_name, credentials: cloud_credentials)
          end

          it 'uses the stored cloud for authorization and requests scopes for its resource' do
            uri = URI(provider.request_account_to_link[:authorize_url])
            scope = CGI.parse(uri.query).fetch('scope').first

            expect(uri.host).to eq(login_host)
            if provider == ExternalCredential::MicrosoftGraph
              resource = graph_resources.fetch(cloud)
              expect(scope.split).to include("#{resource}mail.readwrite", "#{resource}mail.send.shared", 'openid')
            else
              resource = cloud == 'global' ? 'https://outlook.office.com' : 'https://outlook.office365.us'
              expect(scope.split).to include("#{resource}/IMAP.AccessAsUser.All", "#{resource}/SMTP.Send")
            end
          end

          it 'exchanges the authorization code in the same cloud and persists the linked channel endpoints' do
            request = stub_request(:post, token_url)
              .with(body: hash_including('client_id' => 'client', 'code' => 'code'))
              .to_return(body: token_response.to_json)

            channel = provider.link_account('state', { code: 'code', state: 'state' })

            expect(request).to have_been_requested.once
            expect(channel.options.dig(:auth, :cloud)).to eq(cloud)
            if provider == ExternalCredential::MicrosoftGraph
              expect(channel.options.dig(:inbound, :options, :cloud)).to eq(cloud)
              expect(channel.options.dig(:outbound, :options, :cloud)).to eq(cloud)
            else
              hosts = mail_hosts.fetch(cloud)
              expect(channel.options.dig(:inbound, :options, :host)).to eq(hosts.first)
              expect(channel.options.dig(:outbound, :options, :host)).to eq(hosts.last)
            end
          end

          if provider == ExternalCredential::Microsoft365
            it 'migrates a matching legacy mailbox without creating another channel' do
              cloud_config = MicrosoftCloud.new(cloud)
              legacy = create(:email_channel,
                              inbound:  { adapter: 'imap', options: { host: cloud_config.imap_host, user: 'user@example.com', folder: 'Archive', keep_on_server: true } },
                              outbound: { adapter: 'smtp', options: { host: cloud_config.smtp_host, user: 'user@example.com' } })
              stub_request(:post, token_url).to_return(body: token_response.to_json)

              expect { provider.link_account('state', { code: 'code', state: 'state' }) }.not_to change(Channel, :count)
              expect(legacy.reload.area).to eq('Microsoft365::Account')
              expect(legacy.options.dig(:inbound, :options)).to include(folder: 'Archive', keep_on_server: true)
              expect(legacy.options.dig(:auth, :cloud)).to eq(cloud)
            end
          end

          it 'refreshes using the channel cloud after the app configuration changes' do
            token = cloud_credentials.merge(created_at: 1.hour.ago, refresh_token: 'refresh')
            ExternalCredential.find_by(name: provider.provider_name).update!(credentials: credentials)
            request = stub_request(:post, token_url)
              .with(body: hash_including('refresh_token' => 'refresh', 'grant_type' => 'refresh_token'))
              .to_return(body: { access_token: 'new-access', expires_in: 3600 }.to_json)

            refreshed = provider.refresh_token(token)

            expect(refreshed).to include(access_token: 'new-access', cloud: cloud)
            expect(request).to have_been_requested.once
          end
        end
      end

      it 'keeps the Global authorization URL when cloud is omitted' do
        expect(URI(provider.generate_authorize_url(credentials)).host).to eq('login.microsoftonline.com')
      end

      it 'rejects an unknown cloud before attempting authorization' do
        expect { provider.request_account_to_link(credentials.merge(cloud: 'custom'), false) }.to raise_error(ArgumentError)
      end

      it 'rejects national clouds with the shared online-service app' do
        Setting.set('system_online_service', true)
        expect { provider.request_account_to_link(credentials.merge(cloud: 'us_gov', multi_tenant_app: true), false) }
          .to raise_error(Exceptions::UnprocessableContent, 'The shared Microsoft app only supports the Global cloud.')
      end
    end
  end
end

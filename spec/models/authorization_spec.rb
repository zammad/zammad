# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Authorization, type: :model do
  describe 'User assets' do
    subject(:authorization) { create(:twitter_authorization) }

    it 'does update assets after new authorizations created' do
      authorization.user.assets({})
      create(:twitter_authorization, provider: 'twitter2', user: authorization.user)
      assets = authorization.user.reload.assets({})
      expect(assets[:User][authorization.user.id]['accounts'].keys.count).to eq(2)
    end
  end

  describe 'Account linking' do
    let(:auth_hash) do
      {
        'info'        => auth_info,
        'uid'         => auth_uid,
        'provider'    => provider,
        'extra'       => extra,
        'credentials' => auth_credentials,
      }
    end
    let(:auth_info) { {} }
    let(:auth_uid)  { SecureRandom.uuid }
    let(:extra)     { {} }
    let(:auth_credentials) do
      {
        'token'  => '1234',
        'secret' => '1234',
      }
    end
    let(:provider) { 'saml' }
    let(:user) { create(:user, login: auth_uid) }

    before do
      Setting.set('auth_third_party_auto_link_at_inital_login', true)

      user
    end

    shared_examples 'links account with email address', :aggregate_failures do
      it 'linked account' do
        authorization = described_class.create_from_hash(auth_hash)

        expect(authorization.user_id).to eq(user.id)
        expect(authorization.provider).to eq(provider)
      end
    end

    context 'when saml is the provider' do
      context 'when auth provider provides no email address' do
        it 'linked account with uid' do
          authorization = described_class.create_from_hash(auth_hash)

          expect(authorization.user_id).to eq(user.id)
        end
      end
    end

    shared_examples 'does not link account with unverified email address', :aggregate_failures do
      it 'does not link the existing account' do
        expect { described_class.create_from_hash(auth_hash) }
          .to raise_error(Exceptions::UnprocessableContent, %r{Email address.*is already used})
          .and not_change(User, :count)

        expect(described_class.find_by(provider: provider, uid: auth_uid)).to be_nil
      end
    end

    context 'when auth provider provides an email address' do
      let(:email) { 'john.doe@example.com' }
      let(:auth_info) do
        { 'email' => email }
      end
      let(:user) { create(:user, login: auth_uid, email: email) }

      # GitHub, GitLab, Google OAuth2, Facebook, Twitter, LinkedIn and Weibo
      # have no reliable email-verification signal in production (see
      # Authorization::Provider and spec/models/authorization/
      # authorization_sso_account_linking_spec.rb for why), so they link
      # purely on a matching email address, regardless of any
      # "email_verified" value. This is an accepted trade-off, not an
      # oversight - Microsoft 365 is the only provider that actually
      # verifies (see below).
      context 'when the provider has no email verification signal' do
        %w[github gitlab google_oauth2 facebook twitter linkedin weibo].each do |prov|
          context "when \"#{prov}\" is the provider" do
            let(:provider) { prov }

            include_examples 'links account with email address'
          end
        end
      end

      context 'when microsoft_office365 id_token explicitly marks xms_edov false' do
        let(:provider) { 'microsoft_office365' }
        let(:extra)    { { 'id_token_claims' => { 'xms_edov' => false } } }

        include_examples 'does not link account with unverified email address'
      end

      context 'when microsoft_office365 id_token has no xms_edov claim at all' do
        let(:provider) { 'microsoft_office365' }

        include_examples 'links account with email address'
      end

      # In testing, Azure only ever sends "xms_edov" as true or omits it -
      # never an explicit false for an unverified domain (see
      # authorization_sso_account_linking_spec.rb). "require_verified_email_domain"
      # is the opt-in, fail-closed alternative for admins who've configured the
      # "email"/"xms_edov" optional claims on the app registration: unlike the
      # default above, a missing claim blocks linking instead of allowing it.
      context 'when microsoft_office365 strict verification is enabled' do
        let(:provider) { 'microsoft_office365' }

        before do
          Setting.set('auth_microsoft_office365_credentials', { 'require_verified_email_domain' => true })
        end

        context 'when xms_edov is true' do
          let(:extra) { { 'id_token_claims' => { 'xms_edov' => true } } }

          include_examples 'links account with email address'
        end

        context 'when xms_edov is false' do
          let(:extra) { { 'id_token_claims' => { 'xms_edov' => false } } }

          include_examples 'does not link account with unverified email address'
        end

        context 'when xms_edov is absent' do
          include_examples 'does not link account with unverified email address'
        end
      end
    end
  end

  describe 'Account linking notification', sends_notification_emails: true do
    subject(:authorization) { create(:authorization, user: agent, provider: provider) }

    let(:agent)         { create(:agent) }
    let(:provider)      { 'github' }
    let(:provider_name) { 'GitHub' }

    shared_examples 'sending out email notification' do
      it 'sends out an email notification' do
        check_notification do
          authorization

          sent(
            template: 'user_auth_provider',
            user:     authorization.user,
            objects:  hash_including({ user: authorization.user, provider: provider_name })
          )
        end
      end
    end

    shared_examples 'not sending out email notification' do
      it 'does not send out an email notification' do
        check_notification do
          authorization

          not_sent(
            template: 'user_auth_provider',
            user:     authorization.user,
            objects:  hash_including({ user: authorization.user, provider: provider_name })
          )
        end
      end
    end

    context 'with setting turned on' do
      before do
        Setting.set('auth_third_party_linking_notification', true)
      end

      context 'when linking with an existing account' do
        it_behaves_like 'sending out email notification'

        context 'when user has no email address' do
          let(:agent) { create(:agent, email: '') }

          it_behaves_like 'not sending out email notification'
        end
      end

      context 'when creating a new account' do
        let(:agent) { create(:agent, source: 'github') }

        it_behaves_like 'not sending out email notification'
      end

      context 'with SAML as the provider' do
        let(:provider)      { 'saml' }
        let(:provider_name) { 'Custom Provider' }

        before do
          Setting.set('auth_saml_credentials', { display_name: provider_name })
        end

        it_behaves_like 'sending out email notification'
      end
    end

    context 'with setting turned off' do
      before do
        Setting.set('auth_third_party_linking_notification', false)
      end

      it_behaves_like 'not sending out email notification'
    end
  end
end

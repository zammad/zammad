# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Authorization, type: :model do
  describe 'User assets' do
    subject(:authorization) { create(:twitter_authorization) }

    # linked accounts are only part of the assets for the user itself or a privileged caller
    around do |example|
      UserInfo.with_system_context { example.run }
    end

    it 'does update assets after new authorizations created' do
      authorization.user.assets({})
      create(:twitter_authorization, provider: 'twitter2', user: authorization.user)
      assets = authorization.user.reload.assets({})
      expect(assets[:User][authorization.user.id]['accounts'].keys.count).to eq(2)
    end
  end

  describe 'Account linking', :aggregate_failures do
    let(:existing_user) { create(:admin, email: 'admin@example.com') }
    let(:provider)      { 'microsoft_office365' }
    let(:uid)           { SecureRandom.uuid }
    let(:extra)         { {} }

    let(:auth_hash) do
      {
        'provider'    => provider,
        'uid'         => uid,
        'info'        => { 'email' => existing_user.email },
        'extra'       => extra,
        'credentials' => { 'token' => '1234', 'secret' => '1234' },
      }
    end

    before do
      Setting.set('auth_third_party_auto_link_at_inital_login', true)
      existing_user
    end

    # Linking by email is rejected, so a new user is attempted, which then
    # fails on the address that is already taken.
    shared_examples 'not linking the account' do
      it 'does not link the existing account' do
        expect { described_class.create_from_hash(auth_hash, nil) }
          .to raise_error(Exceptions::UnprocessableContent, %r{Email address.*is already used})
          .and not_change(User, :count)

        expect(described_class.find_by(provider: auth_hash['provider'], uid: auth_hash['uid'])).to be_nil
      end
    end

    shared_examples 'linking the account' do
      it 'links the existing account' do
        authorization = described_class.create_from_hash(auth_hash, nil)

        expect(authorization.user).to eq(existing_user)
        expect(authorization.provider).to eq(provider)
      end
    end

    # These providers have no reliable email verification signal, so they
    # link purely on a matching email address.
    context 'when the provider has no email verification signal' do
      %w[github gitlab google_oauth2 facebook linkedin twitter weibo openid_connect].each do |prov|
        context "when \"#{prov}\" is the provider" do
          let(:provider) { prov }

          include_examples 'linking the account'
        end
      end
    end

    context 'when MS365 id_token explicitly marks xms_edov true' do
      let(:extra) { { 'id_token_claims' => { 'xms_edov' => true } } }

      include_examples 'linking the account'
    end

    context 'when MS365 id_token explicitly marks xms_edov false' do
      let(:extra) { { 'id_token_claims' => { 'xms_edov' => false } } }

      include_examples 'not linking the account'
    end

    # Azure omits "xms_edov" instead of sending false for an unverified
    # domain, so the default mode treats a missing claim as no signal.
    context 'when MS365 id_token is not available' do
      include_examples 'linking the account'
    end

    context 'when MS365 strict verification is enabled (require_verified_email_domain)' do
      before do
        Setting.set('auth_microsoft_office365_credentials', { 'require_verified_email_domain' => true })
      end

      context 'when xms_edov is true and the "email" claim matches' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => true, 'email' => existing_user.email } } }

        include_examples 'linking the account'
      end

      context 'when xms_edov is true and the "email" claim matches in a different case' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => true, 'email' => existing_user.email.upcase } } }

        include_examples 'linking the account'
      end

      context 'when xms_edov is false' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => false } } }

        include_examples 'not linking the account'
      end

      context 'when xms_edov is absent' do
        include_examples 'not linking the account'
      end

      # "xms_edov" only vouches for the ID token's "email" claim, not for the
      # separate Graph "/me" address in "info.email" that actually gets linked.
      context 'when xms_edov is true but the "email" claim is a different address' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => true, 'email' => 'somebody.else@example.com' } } }

        include_examples 'not linking the account'
      end

      context 'when xms_edov is true but the "email" claim is absent' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => true } } }

        include_examples 'not linking the account'
      end

      context 'when xms_edov is true but the "email" claim is blank' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => true, 'email' => '' } } }

        include_examples 'not linking the account'
      end
    end

    context 'with SAML' do
      let(:provider) { 'saml' }

      context 'when NameID matches an existing login' do
        before { existing_user.update!(login: uid) }

        include_examples 'linking the account'

        context 'when auth provider provides no email address' do
          let(:auth_hash) { super().merge('info' => {}) }

          include_examples 'linking the account'
        end
      end

      context 'when NameID does not match any login' do
        include_examples 'linking the account'
      end
    end

    context 'when auto-link is disabled' do
      before do
        Setting.set('auth_third_party_auto_link_at_inital_login', false)
      end

      include_examples 'not linking the account'
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

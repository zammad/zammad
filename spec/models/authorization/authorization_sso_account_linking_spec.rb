# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Regression tests for the SSO auto-link account takeover (CWE-287 / CWE-345,
# GitHub coordination-security#91).
#
# An attacker controlling an identity at a configured provider could set that
# identity's email to a victim's address. Because Zammad linked to an existing
# account purely by email (without checking whether the IdP vouched for the
# email), the attacker's (provider, uid) pair was bound to the victim account,
# resulting in a full account takeover.
#
# By default, this fix does NOT reliably stop the attack for any provider.
# Testing against a real Azure tenant found that Microsoft only ever sends
# "xms_edov" as true (verified) or omits it entirely - it does not send an
# explicit false for an unverified domain, which is exactly what the attacker
# technique (setting an arbitrary "mail" attribute on a self-controlled
# tenant) produces. Since the default behaviour treats a missing claim as "no
# signal, allow linking" (to avoid a breaking change for tenants that haven't
# configured the claim), the default-mode check below never actually fires
# against the real attack - see the "MS365 id_token is not available" context.
#
# Real protection for Microsoft 365 requires the opt-in
# "require_verified_email_domain" field on auth_microsoft_office365_credentials
# (see Authorization::Provider::MicrosoftOffice365#strict_email_verification?),
# which admins can enable after configuring the "email" and "xms_edov"
# optional claims on the app registration. It's opt-in, and off by default,
# specifically because it fails closed - enabling it without the Azure-side
# configuration blocks all Microsoft 365 auto-linking outright.
#
# Every other provider (base Authorization::Provider, SAML, OpenID Connect,
# GitHub, GitLab, Google OAuth2, Facebook, Twitter, LinkedIn, Weibo)
# intentionally keeps the original, unverified email-linking behaviour:
# broader verification attempts turned out to be unreliable, unavailable in
# production (wrong gem response shape, no such claim existing), or would
# require a scope/permission change that is a breaking change unsuitable for
# a patch release (e.g. GitHub's all_emails requires the "user:email" scope,
# GitLab's UserInfo endpoint requires "openid email"). This is a deliberate,
# accepted trade-off, not an oversight - the tests below document and pin it
# down.
RSpec.describe Authorization, :aggregate_failures, type: :model do
  describe 'SSO auto-link account takeover protection' do
    let(:victim_admin)  { create(:admin, email: 'admin@victim-helpdesk.com') }
    let(:provider)      { 'microsoft_office365' }
    let(:extra)         { {} }

    let(:attacker_auth_hash) do
      {
        'provider'    => provider,
        'uid'         => 'attacker-controlled-oid-12345',
        'info'        => { 'email' => victim_admin.email },
        'extra'       => extra,
        'credentials' => { 'token' => 'attacker-token', 'secret' => 'attacker-secret' },
      }
    end

    before do
      Setting.set('auth_third_party_auto_link_at_inital_login', true)
      victim_admin
    end

    # When linking by email is rejected, Zammad falls through to creating a new
    # user. Since the victim already owns the email address, the uniqueness
    # validation prevents creation as well, so the attacker neither hijacks the
    # victim nor creates a shadow account.
    shared_examples 'rejecting the takeover' do
      it 'does not bind the attacker identity to the victim account' do
        expect { described_class.create_from_hash(attacker_auth_hash, nil) }
          .to raise_error(Exceptions::UnprocessableContent, %r{Email address.*is already used})
          .and not_change(User, :count)

        expect(described_class.find_by(provider: attacker_auth_hash['provider'], uid: attacker_auth_hash['uid'])).to be_nil
      end
    end

    shared_examples 'links by verified email (legitimate behaviour)' do
      it 'binds the identity to the account it actually belongs to' do
        auth = described_class.create_from_hash(attacker_auth_hash, nil)
        expect(auth.user).to eq(victim_admin)
      end
    end

    # This is the accepted trade-off described above: without a reliable
    # verification signal, these providers link by email exactly as they did
    # before this fix - i.e. the attacker's hash succeeds here too.
    shared_examples 'still links by email (accepted trade-off)' do
      it 'binds the attacker identity to the victim account' do
        auth = described_class.create_from_hash(attacker_auth_hash, nil)
        expect(auth.user).to eq(victim_admin)
      end
    end

    context 'when the provider has no email verification signal' do
      %w[github gitlab google_oauth2 facebook linkedin twitter weibo].each do |prov|
        context "when \"#{prov}\" is the provider" do
          let(:provider) { prov }

          include_examples 'still links by email (accepted trade-off)'
        end
      end
    end

    context 'when OIDC provider has no email_verified claim' do
      let(:provider) { 'openid_connect' }

      include_examples 'still links by email (accepted trade-off)'
    end

    context 'when MS365 id_token explicitly marks xms_edov true' do
      let(:extra) { { 'id_token_claims' => { 'xms_edov' => true } } }

      include_examples 'links by verified email (legitimate behaviour)'
    end

    context 'when MS365 id_token explicitly marks xms_edov false' do
      let(:extra) { { 'id_token_claims' => { 'xms_edov' => false } } }

      include_examples 'rejecting the takeover'
    end

    # This is the realistic case in production: per the file header, real Azure
    # tenants were observed to omit "xms_edov" rather than send it as false for
    # an unverified domain - so the default (non-strict) mode intentionally
    # still links here, same as if the check didn't exist at all.
    context 'when MS365 id_token is not available' do
      include_examples 'still links by email (accepted trade-off)'
    end

    context 'when MS365 strict verification is enabled (require_verified_email_domain)' do
      before do
        Setting.set('auth_microsoft_office365_credentials', { 'require_verified_email_domain' => true })
      end

      context 'when xms_edov is true' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => true } } }

        include_examples 'links by verified email (legitimate behaviour)'
      end

      context 'when xms_edov is false' do
        let(:extra) { { 'id_token_claims' => { 'xms_edov' => false } } }

        include_examples 'rejecting the takeover'
      end

      # Unlike the default mode above, strict mode fails closed: the common
      # real-world case of a missing claim now blocks instead of allowing.
      context 'when xms_edov is absent (the realistic attack case)' do
        include_examples 'rejecting the takeover'
      end
    end

    context 'with SAML' do
      let(:provider) { 'saml' }

      context 'when NameID matches an existing login (Pfad A)' do
        before { victim_admin.update!(login: attacker_auth_hash['uid']) }

        it 'links by NameID/login' do
          authorization = described_class.create_from_hash(attacker_auth_hash, nil)
          expect(authorization.user).to eq(victim_admin)
        end
      end

      context 'when NameID does not match any login (Pfad B)' do
        include_examples 'still links by email (accepted trade-off)'
      end
    end

    context 'when auto-link is disabled' do
      before do
        Setting.set('auth_third_party_auto_link_at_inital_login', false)
      end

      it 'does not link and rejects the duplicate email' do
        expect do
          described_class.create_from_hash(attacker_auth_hash, nil)
        end.to raise_error(Exceptions::UnprocessableContent, %r{Email address.*is already used})
      end
    end
  end
end

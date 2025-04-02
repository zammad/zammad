# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::TwoFactor, current_user_id: 1 do
  let(:user)     { create(:user) }
  let(:instance) { described_class.new(user) }

  before do
    Setting.set('two_factor_authentication_method_authenticator_app', true)
  end

  describe '#all_authentication_methods' do
    it 'returns all methods, including disabled and not setup for user' do
      expect(instance.all_authentication_methods.map { |elem| elem.class.name })
        .to eq([
                 Auth::TwoFactor::AuthenticationMethod::SecurityKeys.name,
                 Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp.name,
               ])
    end

    it 'returns instance for current user' do
      expect(instance.all_authentication_methods.first).to have_attributes(user: user)
    end
  end

  describe '.authentication_method_classes' do
    it 'returns sorted methods' do
      expect(described_class.authentication_method_classes)
        .to eq([
                 Auth::TwoFactor::AuthenticationMethod::SecurityKeys,
                 Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp,
               ])
    end
  end

  describe '#enabled_authentication_methods' do
    it 'returns only enabled method' do
      expect(instance.enabled_authentication_methods)
        .to contain_exactly(be_a(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp))
    end
  end

  describe '#available_authentication_methods' do
    it 'returns available methods' do
      expect(instance.available_authentication_methods)
        .to contain_exactly(be_a(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp))
    end

    context 'when enabled method is not available' do
      before do
        allow_any_instance_of(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
          .to receive(:available?)
          .and_return(false)
      end

      it 'returns available methods' do
        expect(instance.available_authentication_methods).to be_empty
      end
    end
  end

  describe '#enabled?' do
    it 'returns true' do
      expect(instance).to be_enabled
    end

    context 'without enabled methods' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', false)
      end

      it 'returns false' do
        expect(instance).not_to be_enabled
      end
    end
  end

  describe '#verify_configuration?' do
    it 'returns false if invalid method name given' do
      expect(instance)
        .not_to be_verify_configuration('nonexistantmethod', {}, {})
    end

    it 'returns false if invalid payload or configuration given' do
      expect(instance)
        .not_to be_verify_configuration('authenticator_app', {}, {})
    end

    context 'when payload and configuration are valid' do
      before do
        allow_any_instance_of(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
          .to receive(:verify)
          .and_return({ config: :yes, verified: true })
      end

      it 'returns true' do
        expect(instance)
          .to be_verify_configuration('authenticator_app', {}, {})
      end

      it 'creates uer configuration' do
        expect_any_instance_of(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
          .to receive(:create_user_config)
          .with({ config: :yes })

        instance.verify_configuration?('authenticator_app', {}, {})
      end
    end
  end

  describe '#authentication_method_object' do
    before { create(:user_two_factor_preference, :authenticator_app, user: user) }

    it 'returns expected value' do
      expect(instance.authentication_method_object('authenticator_app')).to be_a(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
    end
  end

  describe '#user_authentication_methods' do
    before { create(:user_two_factor_preference, :authenticator_app, user: user) }

    it 'returns expected value' do
      expect(instance.user_authentication_methods).to include(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
    end
  end

  describe '#user_default_method' do
    before { create(:user_two_factor_preference, :authenticator_app, user: user) }

    it 'returns expected value' do
      # 'user' variable is cached + was created before the preference was set.
      user.reload
      expect(instance.user_default_authentication_method).to be_a(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
    end

    context 'when two methods exist' do
      let(:another_method) { create(:user_two_factor_preference, :security_keys, user: user) }

      before do
        Setting.set('two_factor_authentication_method_security_keys', true)
        another_method
        user.reload
        user.preferences[:two_factor_authentication][:default] = 'security_keys'
        user.save!
      end

      it 'returns selected method' do
        user.reload
        expect(instance.user_default_authentication_method)
          .to be_a(Auth::TwoFactor::AuthenticationMethod::SecurityKeys)
      end

      context 'when default method disabled' do
        before do
          Setting.set('two_factor_authentication_method_security_keys', false)
        end

        it 'returns another method' do
          user.reload
          expect(instance.user_default_authentication_method)
            .to be_a(Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp)
        end
      end
    end
  end

  describe '#user_setup_required' do
    let(:user_role)     { create(:role, :agent) }
    let(:non_user_role) { create(:role, :agent) }
    let(:user)          { create(:user, roles: [user_role]) }

    context 'when the setup is required' do
      before do
        Setting.set('two_factor_authentication_enforce_role_ids', [user_role.id])
      end

      it 'returns expected value' do
        expect(instance.user_setup_required?).to be(true)
      end
    end

    context 'when the setup is not required' do
      before do
        Setting.set('two_factor_authentication_enforce_role_ids', [non_user_role.id])
      end

      it 'returns expected value' do
        expect(instance.user_setup_required?).to be(false)
      end
    end
  end

  describe '#user_configured' do
    before do
      Setting.set('two_factor_authentication_method_authenticator_app', true)
    end

    shared_examples 'recovery codes present' do |configured|
      before do
        Auth::TwoFactor::RecoveryCodes.new(user).generate
      end

      it 'returns expected value' do
        expect(instance.user_configured?).to be(configured)
      end
    end

    context 'when a method is configured' do
      before do
        create(:user_two_factor_preference, :authenticator_app, user: user)

        # 'user' variable is cached + was created before the preference was set.
        user.reload
      end

      it 'returns expected value' do
        expect(instance.user_configured?).to be(true)
      end

      it_behaves_like 'recovery codes present', true
    end

    context 'when a method is not configured' do
      before { user.reload }

      it 'returns expected value' do
        expect(instance.user_configured?).to be(false)
      end

      it_behaves_like 'recovery codes present', false
    end

  end

  describe '#verify?' do
    let(:secret) { ROTP::Base32.random_base32 }
    let(:last_otp_at) { 1_256_953_732 } # 2009-10-31T01:48:52Z

    let(:two_factor_pref) do
      create(:user_two_factor_preference, :authenticator_app,
             user:          user,
             method:        method,
             configuration: configuration)
    end

    let(:configuration) do
      {
        last_otp_at: last_otp_at,
        secret:      secret,
      }
    end

    before { two_factor_pref }

    context 'with authenticator app as method' do
      let(:method) { 'authenticator_app' }
      let(:code)   { ROTP::TOTP.new(secret).now }

      shared_examples 'returning true result' do
        it 'returns true result' do
          result = instance.verify?(method, code)

          expect(result).to be true
        end

        it 'updates last otp at timestamp' do
          instance.verify?(method, code)

          expect(user.two_factor_preferences.find_by(method: method).configuration[:last_otp_at]).to be > last_otp_at
        end
      end

      shared_examples 'returning false result' do
        it 'returns false result' do
          result = instance.verify?(method, code)

          expect(result).to be false
        end
      end

      context 'with valid code provided' do
        let(:code) { ROTP::TOTP.new(secret).now }

        it_behaves_like 'returning true result'
      end

      context 'with invalid code provided' do
        let(:code) { 'FOOBAR' }

        it_behaves_like 'returning false result'
      end

      context 'with no configured secret' do
        let(:code) { ROTP::TOTP.new(secret).now }
        let(:configuration) do
          {
            foo: 'bar',
          }
        end

        it_behaves_like 'returning false result'
      end

      context 'with no configured method' do
        let(:code)          { ROTP::TOTP.new(secret).now }
        let(:configuration) { nil }

        it_behaves_like 'returning false result'
      end

      context 'with used recovery code' do
        let(:method) { 'recovery_codes' }
        let(:current_codes)   { Auth::TwoFactor::RecoveryCodes.new(user).generate }
        let(:code)            { current_codes.first }
        let(:two_factor_pref) { nil }

        before do
          current_codes
        end

        it 'returns true result' do
          expect(instance.verify?(method, code)).to be true
        end

        context 'with invalid code provided' do
          let(:code) { 'wrong' }

          it 'returns false result' do
            expect(instance.verify?(method, code)).to be false
          end
        end
      end
    end
  end
end

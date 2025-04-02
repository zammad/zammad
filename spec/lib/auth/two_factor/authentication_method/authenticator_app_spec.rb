# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'rotp'

RSpec.describe Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp do
  subject(:instance) { described_class.new(user) }

  let(:user) { create(:user) }

  shared_examples 'responding to provided instance method' do |method|
    it "responds to '.#{method}'" do
      expect(instance).to respond_to(method)
    end
  end

  it_behaves_like 'responding to provided instance method', :verify
  it_behaves_like 'responding to provided instance method', :initiate_configuration

  describe '#verify' do
    let(:secret)      { ROTP::Base32.random_base32 }
    let(:last_otp_at) { 1_256_953_732 } # 2009-10-31T01:48:52Z

    let(:two_factor_pref) do
      create(:user_two_factor_preference, :authenticator_app,
             user:          user,
             method:        'authenticator_app',
             configuration: configuration)
    end

    let(:configuration) do
      {
        last_otp_at: last_otp_at,
        secret:      secret,
      }
    end

    before { two_factor_pref }

    shared_examples 'returning true result' do
      it 'returns true result' do
        result = instance.verify(code)

        expect(result).to include(
          verified: true
        )
      end

      it 'returns updated timestamp' do
        result = instance.verify(code)

        expect(result[:last_otp_at]).to be > last_otp_at
      end
    end

    shared_examples 'returning false result' do
      it 'returns false result' do
        result, _new_options = instance.verify(code)

        expect(result).to eq({ verified: false })
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
  end

  describe '#initiate_configuration' do
    let(:issuer) { Faker::Internet.unique.domain_word }
    let(:secret) { ROTP::Base32.random_base32 }

    before do
      Setting.set('product_name', issuer)
    end

    it 'returns method config hash' do

      # Mock calls to `ROTP::Base32#random_base32` so they always return the same secret.
      allow(ROTP::Base32).to receive(:random_base32).and_return(secret)

      expect(instance.initiate_configuration).to eq({
                                                      secret:           secret,
                                                      provisioning_uri: "otpauth://totp/#{CGI.escape(issuer)}:#{CGI.escape(user.login)}?secret=#{secret}&issuer=#{CGI.escape(issuer)}",
                                                    })
    end
  end
end

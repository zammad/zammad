# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormSpamProtection::Captcha do
  describe '.providers' do
    it 'auto-discovers exactly the concrete providers' do
      expect(described_class.providers).to contain_exactly(
        FormSpamProtection::Captcha::Altcha,
        FormSpamProtection::Captcha::Turnstile,
        FormSpamProtection::Captcha::Hcaptcha,
        FormSpamProtection::Captcha::FriendlyCaptcha,
        FormSpamProtection::Captcha::Recaptcha,
        FormSpamProtection::Captcha::RecaptchaEnterprise,
      )
    end

    it 'maps each provider key back to its class', :aggregate_failures do
      described_class.providers.each do |klass|
        expect(described_class.by_key(klass.key)).to eq(klass)
      end
    end
  end

  describe '.by_key' do
    it 'returns nil for a blank key', :aggregate_failures do
      expect(described_class.by_key('')).to be_nil
      expect(described_class.by_key(nil)).to be_nil
    end

    it 'returns nil for an unknown key' do
      expect(described_class.by_key('nope')).to be_nil
    end
  end

  describe '.configured_provider' do
    it 'returns nil when no provider is configured' do
      Setting.set('form_ticket_create_captcha_provider', '')

      expect(described_class.configured_provider).to be_nil
    end

    it 'returns an instance of the configured provider' do
      Setting.set('form_ticket_create_captcha_provider', 'turnstile')

      expect(described_class.configured_provider).to be_a(FormSpamProtection::Captcha::Turnstile)
    end
  end
end

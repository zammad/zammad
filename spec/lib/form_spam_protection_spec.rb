# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormSpamProtection do
  def submission(params)
    described_class::Submission.new(params:, request: nil)
  end

  describe '.frontend_config' do
    before do
      Setting.set('form_ticket_create_honeypot', true)
      Setting.set('form_ticket_create_captcha_provider', '')
    end

    it 'includes the honeypot field when enabled' do
      expect(described_class.frontend_config[:honeypot]).to eq({ field: FormSpamProtection::Honeypot::FIELD_NAME })
    end

    it 'omits the honeypot when disabled' do
      Setting.set('form_ticket_create_honeypot', false)

      expect(described_class.frontend_config).not_to have_key(:honeypot)
    end

    it 'omits the captcha when no provider is configured' do
      expect(described_class.frontend_config).not_to have_key(:captcha)
    end

    it 'includes the configured captcha provider configuration' do
      Setting.set('form_ticket_create_captcha_provider', 'altcha')

      expect(described_class.frontend_config[:captcha]).to include(provider: 'altcha', type: 'altcha')
    end

    it 'never leaks the captcha secret to the frontend' do
      Setting.set('form_ticket_create_captcha_provider', 'turnstile')
      Setting.set('form_ticket_create_captcha_options', { 'site_key' => 'site', 'secret' => 'topsecret' })

      expect(described_class.frontend_config.to_s).not_to include('topsecret')
    end
  end

  describe '.verify_request' do
    before { Setting.set('form_ticket_create_honeypot', true) }

    it 'fails when a stateless request check rejects the submission (honeypot filled)' do
      expect(described_class.verify_request(submission({ FormSpamProtection::Honeypot::FIELD_NAME => 'spam' }))).to be(false)
    end

    it 'passes a clean submission' do
      expect(described_class.verify_request(submission({}))).to be(true)
    end
  end

  describe '.verify_challenge' do
    it 'passes when no captcha provider is configured' do
      Setting.set('form_ticket_create_captcha_provider', '')

      expect(described_class.verify_challenge(submission({}))).to be(true)
    end
  end
end

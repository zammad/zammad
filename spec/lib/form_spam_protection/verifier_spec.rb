# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormSpamProtection::Verifier do
  def submission(params: {})
    FormSpamProtection::Submission.new(params:, request: nil)
  end

  before do
    Setting.set('form_ticket_create_honeypot', true)
    Setting.set('form_ticket_create_captcha_provider', '')
  end

  describe '#request_valid?' do
    it 'passes a clean submission' do
      expect(described_class.new(submission).request_valid?).to be(true)
    end

    it 'fails when the honeypot is filled in' do
      expect(described_class.new(submission(params: { FormSpamProtection::Honeypot::FIELD_NAME => 'x' })).request_valid?).to be(false)
    end

    it 'skips the honeypot check when it is disabled' do
      Setting.set('form_ticket_create_honeypot', false)

      expect(described_class.new(submission(params: { FormSpamProtection::Honeypot::FIELD_NAME => 'x' })).request_valid?).to be(true)
    end
  end

  describe '#challenge_valid?' do
    it 'passes when no captcha provider is configured' do
      expect(described_class.new(submission).challenge_valid?).to be(true)
    end

    it 'runs the configured captcha provider' do
      Setting.set('form_ticket_create_captcha_provider', 'turnstile')
      Setting.set('form_ticket_create_captcha_options', { 'secret' => 's' })
      allow(UserAgent).to receive(:post).and_return(
        instance_double(UserAgent::Result, success?: true, code: 200, body: '{"success":false}')
      )

      expect(described_class.new(submission(params: { 'cf-turnstile-response' => 'tok' })).challenge_valid?).to be(false)
    end
  end
end

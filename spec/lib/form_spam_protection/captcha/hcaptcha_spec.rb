# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/token_verification'
require_relative 'shared_examples/secret_free_frontend_config'

RSpec.describe FormSpamProtection::Captcha::Hcaptcha do
  subject(:provider) { described_class.new }

  before do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site', 'secret' => 'secret' })
  end

  it_behaves_like 'a token-verification captcha',
                  response_field: 'h-captcha-response',
                  verify_url:     'https://api.hcaptcha.com/siteverify'
  it_behaves_like 'a captcha that keeps secrets out of the frontend config'

  it 'exposes the widget configuration', :aggregate_failures do
    expect(provider.frontend_config).to include(
      provider:       'hcaptcha',
      type:           'widget',
      widget_class:   'h-captcha',
      response_field: 'h-captcha-response',
      global:         'hcaptcha',
      site_key:       'site',
    )
  end

  it 'sends the secret, response and remote IP to siteverify' do
    allow(UserAgent).to receive(:post).and_return(
      instance_double(UserAgent::Result, success?: true, code: 200, body: '{"success":true}')
    )

    provider.verify(FormSpamProtection::Submission.new(
                      params:  { 'h-captcha-response' => 'token' },
                      request: instance_double(ActionDispatch::Request, remote_ip: '203.0.113.1'),
                    ))

    expect(UserAgent).to have_received(:post).with(
      'https://api.hcaptcha.com/siteverify',
      hash_including(secret: 'secret', response: 'token', remoteip: '203.0.113.1'),
      hash_including(verify_ssl: true),
    )
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/token_verification'
require_relative 'shared_examples/secret_free_frontend_config'

RSpec.describe FormSpamProtection::Captcha::FriendlyCaptcha do
  subject(:provider) { described_class.new }

  before do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site', 'secret' => 'secret' })
  end

  it_behaves_like 'a token-verification captcha',
                  response_field: 'frc-captcha-solution',
                  verify_url:     'https://api.friendlycaptcha.com/api/v1/siteverify'
  it_behaves_like 'a captcha that keeps secrets out of the frontend config'

  it 'exposes a widget that is initialized explicitly for late (dynamically added) forms', :aggregate_failures do
    config = provider.frontend_config

    expect(config).to include(provider: 'friendly_captcha', widget_class: 'frc-captcha', global: 'friendlyChallenge')
    expect(config[:widget_instance]).to be(true)
  end

  it 'verifies using the solution/sitekey parameter shape' do
    allow(UserAgent).to receive(:post).and_return(
      instance_double(UserAgent::Result, success?: true, code: 200, body: '{"success":true}')
    )

    provider.verify(FormSpamProtection::Submission.new(
                      params:  { 'frc-captcha-solution' => 'solution' },
                      request: instance_double(ActionDispatch::Request, remote_ip: '203.0.113.1'),
                    ))

    expect(UserAgent).to have_received(:post).with(
      'https://api.friendlycaptcha.com/api/v1/siteverify',
      hash_including(solution: 'solution', secret: 'secret', sitekey: 'site'),
      hash_including(verify_ssl: true),
    )
  end
end

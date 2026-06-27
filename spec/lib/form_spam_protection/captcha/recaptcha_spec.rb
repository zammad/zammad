# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/token_verification'
require_relative 'shared_examples/secret_free_frontend_config'

RSpec.describe FormSpamProtection::Captcha::Recaptcha do
  subject(:provider) { described_class.new }

  before do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site', 'secret' => 'secret' })
  end

  it_behaves_like 'a token-verification captcha',
                  response_field: 'g-recaptcha-response',
                  verify_url:     'https://www.google.com/recaptcha/api/siteverify',
                  valid_body:     { success: true, score: 0.9 }
  it_behaves_like 'a captcha that keeps secrets out of the frontend config'

  def submission(response)
    FormSpamProtection::Submission.new(
      params:  { 'g-recaptcha-response' => response },
      request: instance_double(ActionDispatch::Request, remote_ip: '203.0.113.1'),
    )
  end

  def stub_siteverify(body)
    allow(UserAgent).to receive(:post).and_return(
      instance_double(UserAgent::Result, success?: true, code: 200, body: body.to_json)
    )
  end

  it 'exposes an invisible score widget configuration', :aggregate_failures do
    config = provider.frontend_config

    expect(config).to include(provider: 'recaptcha', type: 'score', response_field: 'g-recaptcha-response', global: 'grecaptcha', action: 'submit')
    expect(config[:script_url]).to include('render=site')
    expect(config[:widget_class]).to be_nil
  end

  it 'rejects a successful response with a score below the minimum' do
    stub_siteverify(success: true, score: 0.1)

    expect(provider.verify(submission('token'))).to be(false)
  end

  it 'accepts a response whose score exactly meets the minimum' do
    stub_siteverify(success: true, score: 0.5)

    expect(provider.verify(submission('token'))).to be(true)
  end

  it 'rejects an unsuccessful response regardless of score' do
    stub_siteverify(success: false, score: 0.9)

    expect(provider.verify(submission('token'))).to be(false)
  end

  it 'honors a configured minimum score' do
    Setting.set('form_ticket_create_captcha_options', { 'secret' => 'secret', 'min_score' => '0.95' })
    stub_siteverify(success: true, score: 0.9)

    expect(provider.verify(submission('token'))).to be(false)
  end
end

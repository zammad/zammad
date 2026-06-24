# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/secret_free_frontend_config'

RSpec.describe FormSpamProtection::Captcha::RecaptchaEnterprise do
  subject(:provider) { described_class.new }

  before do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site', 'project_id' => 'proj', 'api_key' => 'key' })
  end

  it_behaves_like 'a captcha that keeps secrets out of the frontend config'

  def submission(response)
    FormSpamProtection::Submission.new(
      params:  { 'g-recaptcha-response' => response },
      request: instance_double(ActionDispatch::Request, remote_ip: '203.0.113.1'),
    )
  end

  def stub_assessment(data:, http_success: true, code: 200)
    allow(UserAgent).to receive(:post).and_return(
      instance_double(UserAgent::Result, success?: http_success, code:, data:)
    )
  end

  it 'exposes an invisible enterprise score widget configuration', :aggregate_failures do
    config = provider.frontend_config

    expect(config).to include(provider: 'recaptcha_enterprise', type: 'score', global: 'grecaptcha.enterprise', response_field: 'g-recaptcha-response')
    expect(config[:script_url]).to include('enterprise.js?render=site')
  end

  it 'assesses the token via the enterprise API and accepts a valid, high-score response', :aggregate_failures do
    stub_assessment(data: { 'tokenProperties' => { 'valid' => true }, 'riskAnalysis' => { 'score' => 0.9 } })

    expect(provider.verify(submission('token'))).to be(true)
    expect(UserAgent).to have_received(:post).with(
      'https://recaptchaenterprise.googleapis.com/v1/projects/proj/assessments',
      { event: { token: 'token', siteKey: 'site', expectedAction: 'submit' } },
      hash_including(json: true, headers: { 'X-Goog-Api-Key' => 'key' }),
    )
  end

  it 'rejects an invalid token' do
    stub_assessment(data: { 'tokenProperties' => { 'valid' => false }, 'riskAnalysis' => { 'score' => 0.9 } })

    expect(provider.verify(submission('token'))).to be(false)
  end

  it 'rejects a score below the minimum' do
    stub_assessment(data: { 'tokenProperties' => { 'valid' => true }, 'riskAnalysis' => { 'score' => 0.1 } })

    expect(provider.verify(submission('token'))).to be(false)
  end

  it 'rejects a missing response token without calling the API', :aggregate_failures do
    allow(UserAgent).to receive(:post)

    expect(provider.verify(submission(''))).to be(false)
    expect(UserAgent).not_to have_received(:post)
  end

  it 'rejects when project ID or API key is not configured' do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site' })

    expect(provider.verify(submission('token'))).to be(false)
  end

  it 'fails closed when the assessment request fails' do
    stub_assessment(data: nil, http_success: false, code: 500)

    expect(provider.verify(submission('token'))).to be(false)
  end
end

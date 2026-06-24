# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Behaviour shared by every CAPTCHA provider that verifies a response token via a
# server-side "siteverify" HTTP call. Guarantees each provider rejects missing
# tokens, missing secrets and bad responses, and — most importantly — fails
# closed when the provider is unreachable or replies with garbage.
#
# @param response_field [String] the form field carrying the token
# @param verify_url [String] the expected siteverify endpoint
# @param valid_body [Hash] a provider response that should pass (default: success)
RSpec.shared_examples 'a token-verification captcha' do |params|
  subject(:provider) { described_class.new }

  let(:response_field) { params.fetch(:response_field) }
  let(:verify_url)     { params.fetch(:verify_url) }
  let(:valid_body)     { params.fetch(:valid_body, { success: true }) }

  before do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site', 'secret' => 'topsecret' })
  end

  def token_submission(response)
    FormSpamProtection::Submission.new(
      params:  { response_field => response },
      request: instance_double(ActionDispatch::Request, remote_ip: '203.0.113.1'),
    )
  end

  def stub_siteverify(body:, http_success: true, code: 200)
    serialized = body.is_a?(String) ? body : body.to_json
    allow(UserAgent).to receive(:post).and_return(
      instance_double(UserAgent::Result, success?: http_success, code:, body: serialized)
    )
  end

  it 'verifies a valid response token against the expected endpoint', :aggregate_failures do
    stub_siteverify(body: valid_body)

    expect(provider.verify(token_submission('token'))).to be(true)
    expect(UserAgent).to have_received(:post).with(verify_url, anything, hash_including(verify_ssl: true))
  end

  it 'rejects an invalid response token' do
    stub_siteverify(body: { success: false })

    expect(provider.verify(token_submission('token'))).to be(false)
  end

  it 'rejects a missing response token without calling the provider', :aggregate_failures do
    allow(UserAgent).to receive(:post)

    expect(provider.verify(token_submission(''))).to be(false)
    expect(UserAgent).not_to have_received(:post)
  end

  it 'rejects when no secret is configured, without calling the provider', :aggregate_failures do
    Setting.set('form_ticket_create_captcha_options', { 'sitekey' => 'site' })
    allow(UserAgent).to receive(:post)

    expect(provider.verify(token_submission('token'))).to be(false)
    expect(UserAgent).not_to have_received(:post)
  end

  it 'fails closed when the provider request fails' do
    stub_siteverify(body: valid_body, http_success: false, code: 500)

    expect(provider.verify(token_submission('token'))).to be(false)
  end

  it 'fails closed on a malformed provider response' do
    stub_siteverify(body: 'not-json')

    expect(provider.verify(token_submission('token'))).to be(false)
  end
end

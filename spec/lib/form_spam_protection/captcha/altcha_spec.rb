# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/secret_free_frontend_config'

RSpec.describe FormSpamProtection::Captcha::Altcha do
  subject(:provider) { described_class.new }

  let(:challenge) { provider.challenge }

  it_behaves_like 'a captcha that keeps secrets out of the frontend config'

  # Brute-force the proof-of-work number the widget would compute in the browser.
  def solve(challenge)
    number = (0..challenge[:maxnumber]).find { |n| Digest::SHA256.hexdigest("#{challenge[:salt]}#{n}") == challenge[:challenge] }

    {
      algorithm: challenge[:algorithm],
      challenge: challenge[:challenge],
      number:,
      salt:      challenge[:salt],
      signature: challenge[:signature],
    }
  end

  def encode(solution)
    Base64.strict_encode64(solution.to_json)
  end

  def submission(payload)
    FormSpamProtection::Submission.new(params: { 'altcha' => payload }, request: nil)
  end

  it 'exposes a challenge URL to the widget (fetched fresh, not embedded)', :aggregate_failures do
    config = provider.frontend_config

    expect(config).to include(provider: 'altcha', type: 'altcha', response_field: 'altcha')
    expect(config[:challenge_url]).to end_with('/form_captcha_challenge')
    expect(config).not_to have_key(:challenge)
  end

  it 'generates a signed, time-limited proof-of-work challenge' do
    expect(provider.challenge).to include(:algorithm, :challenge, :salt, :signature, :maxnumber)
  end

  it 'accepts a correctly solved challenge' do
    expect(provider.verify(submission(encode(solve(challenge))))).to be(true)
  end

  it 'rejects a missing solution' do
    expect(provider.verify(submission(nil))).to be(false)
  end

  it 'rejects a malformed payload' do
    expect(provider.verify(submission('not-base64-json'))).to be(false)
  end

  it 'rejects a tampered solution number' do
    expect(provider.verify(submission(encode(solve(challenge).merge(number: -1))))).to be(false)
  end

  it 'rejects a forged signature' do
    expect(provider.verify(submission(encode(solve(challenge).merge(signature: 'deadbeef'))))).to be(false)
  end

  it 'rejects an expired challenge' do
    solution = solve(challenge)

    travel_to(2.hours.from_now) do
      expect(provider.verify(submission(encode(solution)))).to be(false)
    end
  end

  it 'rejects a reused solution (replay protection)', :aggregate_failures do
    payload = encode(solve(challenge))

    expect(provider.verify(submission(payload))).to be(true)
    expect(provider.verify(submission(payload))).to be(false)
  end
end

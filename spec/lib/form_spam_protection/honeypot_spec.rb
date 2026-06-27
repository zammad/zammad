# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormSpamProtection::Honeypot do
  subject(:honeypot) { described_class.new }

  def submission(params)
    FormSpamProtection::Submission.new(params:, request: nil)
  end

  let(:field) { described_class::FIELD_NAME }

  it 'passes when the honeypot field is absent or empty', :aggregate_failures do
    expect(honeypot.verify(submission({}))).to be(true)
    expect(honeypot.verify(submission({ field => '' }))).to be(true)
  end

  it 'rejects when the honeypot field is filled in' do
    expect(honeypot.verify(submission({ field => 'http://spam.example.com' }))).to be(false)
  end

  it 'rejects when the honeypot field contains only whitespace' do
    expect(honeypot.verify(submission({ field => '   ' }))).to be(false)
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Runtime::Cursor, :aggregate_failures do
  let(:scope) { { 'query' => 'outlook', 'customer' => 'anna@example.com' } }

  it 'gives back the position for the list it was given for' do
    cursor = described_class.encode(offset: 20, scope:)

    expect(cursor).to match(%r{\A[A-Za-z0-9_-]+\z})
    expect(described_class.decode(cursor, scope:)).to eq(20)
  end

  it 'starts a list without a cursor at its beginning' do
    expect(described_class.decode(nil, scope:)).to eq(0)
  end

  it 'refuses a cursor of another list' do
    cursor = described_class.encode(offset: 20, scope:)

    expect(described_class.decode(cursor, scope: scope.merge('customer' => 'ben@example.com'))).to be_nil
  end

  it 'refuses what it did not give' do
    forged = Base64.urlsafe_encode64({ offset: 20, scope: 'nope' }.to_json, padding: false)

    ['20', 'next', '', '%%%', Base64.urlsafe_encode64('[1]'), described_class.encode(offset: -1, scope:), forged].each do |cursor|
      expect(described_class.decode(cursor, scope:)).to be_nil, cursor
    end
  end
end

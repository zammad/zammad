# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Locator::Organization, :aggregate_failures do
  def locator(arguments)
    described_class.new(arguments.stringify_keys)
  end

  it 'names the organization by its ID' do
    expect(locator(organization_id: 3).record_id).to eq(3)
    expect(described_class.named?({ 'organization_id' => 3 })).to be(true)
    expect(described_class.named?({})).to be(false)
  end

  it 'takes an organization among the given IDs or one the agent named by ID, and no other' do
    expect(locator(organization_id: 3).named_by?(ids: [3], texts: [])).to be(true)
    expect(locator(organization_id: 3).named_by?(ids: [], texts: ['Is organization ID 3 a VIP?'])).to be(true)
    expect(locator(organization_id: 3).named_by?(ids: [4], texts: ['Ticket 3 is open.'])).to be(false)
  end
end

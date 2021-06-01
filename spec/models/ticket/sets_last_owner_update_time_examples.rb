# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples 'TicketSetsLastOwnerUpdateTime' do
  subject { create(described_class.name.underscore) }

  let(:new_owner) { create(:agent, groups: [subject.group]) }

  it 'can only be loaded for tickets' do
    expect(described_class).to eq Ticket
  end

  before do
    travel_to Time.zone.now
  end

  it 'has no last_owner_update_at initially' do
    expect(subject.last_owner_update_at).to be_nil
  end

  it 'gets last_owner_update_at after user change' do
    subject.update(owner: new_owner)
    expect(subject.last_owner_update_at).to eq(Time.zone.now)
  end
end

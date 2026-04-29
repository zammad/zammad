# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::History::Group, current_user_id: -> { user.id } do
  before do
    object
  end

  context 'when history object is a ticket' do
    let(:group)  { create(:group) }
    let(:object) { create(:ticket, group: group) }

    context 'when user is not authorized to view the ticket' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:agent) }

      it 'raises an error' do
        expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the ticket' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:agent, groups: [group]) }

      it 'returns a group of history records for the ticket', :aggregate_failures do
        expect { service_result }.not_to raise_error
        expect(service_result).to be_an_instance_of(Array)
        expect(service_result.first).to include(
          :created_at, :records
        )
        expect(service_result.first[:records].first).to include(
          :issuer, :events
        )
        expect(service_result.first[:records].first[:events].first).not_to include(:issuer)
      end
    end
  end

  context 'when history object is a user' do
    let(:object) { create(:user) }

    context 'when user is not authorized to view the user' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:customer) }

      it 'raises an error' do
        expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the user' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:admin) }

      it 'returns a group of history records for the user', :aggregate_failures do
        expect { service_result }.not_to raise_error
        expect(service_result).to be_an_instance_of(Array)
        expect(service_result.first).to include(
          :created_at, :records
        )
        expect(service_result.first[:records].first).to include(
          :issuer, :events
        )
        expect(service_result.first[:records].first[:events].first).not_to include(:issuer)
      end
    end
  end

  context 'when events straddle an epoch-aligned 15-second boundary' do
    subject(:service_result) { described_class.with_current_user(user).execute(object:) }

    let(:group)  { create(:group) }
    let(:object) { create(:ticket, group:) }
    let(:user)   { create(:agent, groups: [group]) }

    # Unix timestamp 1_777_494_660 is divisible by 15 (epoch-aligned boundary).
    # t1 is 7 seconds before it, t2 is 2 seconds after - 9 seconds apart and
    # within the default 15-second interval, so they must land in one group.
    let(:t1) { Time.at(1_777_494_653).utc }
    let(:t2) { Time.at(1_777_494_662).utc }

    before do
      allow(Service::History::List).to receive(:execute).and_return([
                                                                      { created_at: t1, issuer: user, action: 'created', object: { klass: 'Ticket' }, attribute: nil, changes: { from: nil, to: nil } },
                                                                      { created_at: t2, issuer: user, action: 'updated', object: { klass: 'Ticket' }, attribute: 'title', changes: { from: 'Old', to: 'New' } },
                                                                    ])
    end

    it 'keeps events within the interval together in one group' do
      expect(service_result.size).to eq(1)
    end
  end

  context 'when history object is a organization' do
    let(:object) { create(:organization) }

    context 'when user is not authorized to view the organization' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:customer) }

      it 'raises an error' do
        expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the organization' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:admin) }

      it 'returns a group of history records for the organization', :aggregate_failures do
        expect { service_result }.not_to raise_error
        expect(service_result).to be_an_instance_of(Array)
        expect(service_result.first).to include(
          :created_at, :records
        )
        expect(service_result.first[:records].first).to include(
          :issuer, :events
        )
        expect(service_result.first[:records].first[:events].first).not_to include(:issuer)
      end
    end
  end
end

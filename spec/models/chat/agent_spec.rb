# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Chat::Agent, type: :model do

  describe '.state' do

    let(:user) { create(:agent) }

    context 'when no record exists for User' do

      it 'returns false' do
        expect(described_class.state(1337)).to be(false)
      end
    end

    context 'when active flag is set to true' do

      before do
        create(:'chat/agent', active: true, updated_by: user)
      end

      it 'returns true' do
        expect(described_class.state(user.id)).to be(true)
      end
    end

    context 'when active flag is set to false' do

      before do
        create(:'chat/agent', active: false, updated_by: user)
      end

      it 'returns false' do
        expect(described_class.state(user.id)).to be(false)
      end
    end

    context 'when setting state for not existing record' do
      it 'creates a record' do
        expect { described_class.state(user.id, true) }.to change { described_class.exists?(updated_by: user) }.from(false).to(true)
      end
    end

    context 'when setting same state for record' do

      let(:record) { create(:'chat/agent', active: true, updated_by: user) }

      before do
        # avoid race condition with same updated_at time
        record
        travel_to 5.minutes.from_now
      end

      it 'updates updated_at timestamp' do
        expect { described_class.state(record.updated_by_id, record.active) }.to change { record.reload.updated_at }
      end

      it 'returns false' do
        expect(described_class.state(record.updated_by_id, record.active)).to eq(false)
      end
    end

    context 'when setting different state for record' do

      let(:record) { create(:'chat/agent', active: true, updated_by: user) }

      before do
        # avoid race condition with same updated_at time
        record
        travel_to 5.minutes.from_now
      end

      it 'updates updated_at timestamp' do
        expect { described_class.state(record.updated_by_id, !record.active) }.to change { record.reload.updated_at }
      end

      it 'returns true' do
        expect(described_class.state(record.updated_by_id, !record.active)).to eq(true)
      end
    end
  end
end

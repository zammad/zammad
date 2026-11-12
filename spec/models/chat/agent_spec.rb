# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
        expect(described_class.state(record.updated_by_id, record.active)).to be(false)
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
        expect(described_class.state(record.updated_by_id, !record.active)).to be(true)
      end
    end
  end

  describe '.beating?' do
    let(:user) { create(:agent) }

    def agent_updated(time)
      create(:'chat/agent', updated_by: user).tap { |record| record.update_columns(updated_at: time) }
    end

    it 'is true within two minutes of the last beat' do
      agent_updated(1.minute.ago)

      expect(described_class.beating?(user.id)).to be(true)
    end

    it 'is false after that' do
      agent_updated(3.minutes.ago)

      expect(described_class.beating?(user.id)).to be(false)
    end

    it 'is true whether the agent is available or not' do
      agent_updated(1.minute.ago).update!(active: false)

      expect(described_class.beating?(user.id)).to be(true)
    end

    it 'is false for an agent without a record' do
      expect(described_class.beating?(user.id)).to be(false)
    end

    it 'does not take the beat of another agent for it' do
      create(:'chat/agent', updated_by: create(:agent))

      expect(described_class.beating?(user.id)).to be(false)
    end
  end
end

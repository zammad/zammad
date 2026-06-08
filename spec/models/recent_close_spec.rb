# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RecentClose, type: :model do
  subject { create(:recent_close) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:recently_closed_object) }
  it { is_expected.to validate_uniqueness_of(:user).scoped_to(:recently_closed_object_type, :recently_closed_object_id) }

  describe '.upsert_closing_time!' do
    let(:user)   { create(:agent) }
    let(:object) { create(:ticket) }

    it 'creates a new recent close record' do
      recent_close = described_class.upsert_closing_time!(user, object)

      expect(recent_close).to have_attributes(
        id:                     be_present,
        user:,
        recently_closed_object: object
      )
    end

    it 'creates a new recent close if none exists' do
      expect { described_class.upsert_closing_time!(user, object) }
        .to change(described_class, :count).by(1)
    end

    it 'updates timestamp if a recent close already exists' do
      existing = create(:recent_close, user:, recently_closed_object: object)

      travel 1.minute

      expect { described_class.upsert_closing_time!(user, object) }
        .to change { existing.reload.updated_at }
    end

    it 'does not create a new recent close if a matching one already exists' do
      create(:recent_close, user:, recently_closed_object: object)

      expect { described_class.upsert_closing_time!(user, object) }
        .not_to change(described_class, :count)
    end

    it 'creates a new recent close for the different user' do
      create(:recent_close, user: create(:user), recently_closed_object: object)

      expect { described_class.upsert_closing_time!(user, object) }
        .to change(described_class, :count).by(1)
    end

    it 'creates a new recent close for the different object' do
      create(:recent_close, user:, recently_closed_object: create(:ticket))

      expect { described_class.upsert_closing_time!(user, object) }
        .to change(described_class, :count).by(1)
    end
  end

  describe '.cleanup' do
    it 'deletes old recent closes' do
      create(:recent_close)
      travel 5.weeks
      create(:recent_close)

      travel 2.months

      expect { described_class.cleanup }.to change(described_class, :count).by(-1)
    end

    it 'keeps old recent closes that were bumped recently' do
      old_close = create(:recent_close)
      travel 5.weeks
      create(:recent_close)

      travel 2.months

      old_close.touch

      expect { described_class.cleanup }.not_to change(described_class, :count)
    end
  end

  describe '#trigger_subscriptions' do
    let(:user) { create(:agent) }

    it 'triggers subscription after creating' do
      allow(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to receive(:trigger)

      described_class.upsert_closing_time!(user, create(:ticket))

      expect(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to have_received(:trigger)
        .with({}, scope: user.id)
    end

    it 'triggers subscription after updating' do
      described_class.upsert_closing_time!(user, create(:ticket))

      travel 1.day

      allow(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to receive(:trigger)

      described_class.upsert_closing_time!(user, create(:ticket))

      expect(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to have_received(:trigger)
        .with({}, scope: user.id)
    end

    it 'trigger subscription after destroying' do
      recent_close = described_class.upsert_closing_time!(user, create(:ticket))

      allow(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to receive(:trigger)

      recent_close.destroy

      expect(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to have_received(:trigger)
        .with({}, scope: user.id)
    end

    it 'does not trigger subscription after deleting' do
      recent_close = described_class.upsert_closing_time!(user, create(:ticket))

      allow(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to receive(:trigger)

      recent_close.delete

      expect(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .not_to have_received(:trigger)
    end
  end

  describe '.destroy_logs' do
    it 'deletes recent closes for the given object' do
      ticket1 = create(:ticket)
      ticket2 = create(:ticket)
      user1   = create(:agent)
      user2   = create(:agent)
      _recent_close1 = create(:recent_close, recently_closed_object: ticket1, user: user1)
      _recent_close2 = create(:recent_close, recently_closed_object: ticket1, user: user2)
      recent_close3 = create(:recent_close, recently_closed_object: ticket2, user: user2)

      described_class.destroy_logs(ticket1)

      expect(described_class.all).to contain_exactly(recent_close3)
    end

    it 'triggers push notification with correct scope' do
      ticket = create(:ticket)
      user   = create(:agent)
      create(:recent_close, recently_closed_object: ticket, user: user)

      allow(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to receive(:trigger)

      described_class.destroy_logs(ticket)

      expect(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to have_received(:trigger)
        .with({}, scope: user.id)
    end

    it 'triggers push notification for each user' do
      ticket = create(:ticket)
      user1   = create(:agent)
      user2   = create(:agent)
      create(:recent_close, recently_closed_object: ticket, user: user1)
      create(:recent_close, recently_closed_object: ticket, user: user2)
      create(:recent_close, recently_closed_object: create(:ticket), user: user2)

      allow(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to receive(:trigger)

      described_class.destroy_logs(ticket)

      expect(Gql::Subscriptions::User::Current::RecentClose::Updates)
        .to have_received(:trigger)
        .twice
    end
  end
end

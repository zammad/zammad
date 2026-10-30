# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::OnlineNotification::MarkAllAsSeen do
  subject(:service_result) { described_class.with_current_user(agent).execute }

  let(:agent)       { create(:agent) }
  let(:other_agent) { create(:agent) }
  let(:unseen)      { create_list(:online_notification, 2, user: agent) }
  let(:seen)        { create(:online_notification, user: agent, seen: true, updated_by_id: other_agent.id, updated_at: 1.day.ago) }
  let(:foreign)     { create(:online_notification, user: other_agent) }

  before do
    unseen
    seen
    foreign
  end

  it 'marks every unseen notification of the current user as seen' do
    expect { service_result }
      .to change { OnlineNotification.where(user: agent, seen: false).count }
      .from(2).to(0)
  end

  it 'records the current user as the one who saw them' do
    service_result

    expect(unseen.map(&:reload)).to all(have_attributes(updated_by_id: agent.id, updated_at: be_within(1.minute).of(Time.zone.now)))
  end

  it 'leaves notifications that were seen already alone' do
    expect { service_result }.not_to change { seen.reload.updated_at }
  end

  it 'keeps notifications of other users unseen' do
    expect { service_result }.not_to change { foreign.reload.seen }
  end

  it 'returns how many notifications it marked' do
    expect(service_result).to eq(2)
  end

  it 'notifies the clients of the current user once' do
    allow(Sessions).to receive(:send_to)

    service_result

    expect(Sessions)
      .to have_received(:send_to)
      .with(agent.id, event: 'OnlineNotification::changed', data: {})
      .once
  end

  it 'triggers the subscriptions of the current user once' do
    allow(Gql::Subscriptions::OnlineNotificationsCount).to receive(:trigger)

    service_result

    expect(Gql::Subscriptions::OnlineNotificationsCount)
      .to have_received(:trigger).with(agent, scope: agent.id)
      .once
  end

  context 'when the current user has no unseen notifications' do
    let(:unseen) { [] }

    it 'returns zero' do
      expect(service_result).to eq(0)
    end

    it 'does not notify the clients' do
      allow(Sessions).to receive(:send_to)

      service_result

      expect(Sessions).not_to have_received(:send_to)
    end

    it 'does not trigger the subscriptions' do
      allow(Gql::Subscriptions::OnlineNotificationsCount).to receive(:trigger)

      service_result

      expect(Gql::Subscriptions::OnlineNotificationsCount).not_to have_received(:trigger)
    end
  end

  it 'requires a current user' do
    expect { described_class.execute }
      .to raise_error(%r{Current user is required})
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::OnlineNotification::DeleteAll do
  subject(:service_result) { described_class.with_current_user(agent).execute }

  let(:agent)              { create(:agent) }
  let(:other_agent)        { create(:agent) }
  let(:notification_count) { 2 }

  before do
    create_list(:online_notification, notification_count, user: agent)
    create(:online_notification, user: other_agent)
  end

  it 'deletes all notifications of the current user' do
    expect { service_result }
      .to change { OnlineNotification.where(user: agent).count }
      .from(2).to(0)
  end

  it 'keeps notifications of other users' do
    expect { service_result }
      .not_to change { OnlineNotification.where(user: other_agent).count }
  end

  it 'notifies the clients of the current user' do
    allow(Sessions).to receive(:send_to)

    service_result

    expect(Sessions)
      .to have_received(:send_to)
      .with(agent.id, event: 'OnlineNotification::changed', data: {})
  end

  it 'triggers the subscriptions of the current user' do
    allow(Gql::Subscriptions::OnlineNotificationsCount).to receive(:trigger)

    service_result

    expect(Gql::Subscriptions::OnlineNotificationsCount)
      .to have_received(:trigger).with(agent, scope: agent.id)
  end

  context 'when the current user has no notifications' do
    let(:notification_count) { 0 }

    it 'succeeds' do
      expect(service_result).to be(true)
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

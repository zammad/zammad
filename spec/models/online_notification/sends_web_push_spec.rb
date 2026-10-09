# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OnlineNotification::SendsWebPush, performs_jobs: true do
  let(:agent)  { create(:agent) }
  let(:ticket) { create(:ticket) }

  def add_notification
    create(:online_notification, o: ticket, user_id: agent.id)
  end

  context 'when the recipient subscribed devices' do
    let!(:subscriptions) { create_list(:push_subscription, 2, user: agent) }

    it 'enqueues one delivery per device', :aggregate_failures do
      notification = add_notification

      subscriptions.each do |subscription|
        expect(WebPushNotificationJob).to have_been_enqueued.with(notification, subscription)
      end
      expect(WebPushNotificationJob).to have_been_enqueued.exactly(2).times
    end
  end

  context 'when the recipient has no subscribed device' do
    it 'enqueues nothing' do
      expect { add_notification }.not_to have_enqueued_job(WebPushNotificationJob)
    end
  end
end

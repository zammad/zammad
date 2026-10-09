# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe WebPushNotificationJob, type: :job do
  include ActiveJob::TestHelper

  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:) }
  # Created before the subscription, so it enqueues no delivery of its own.
  let!(:notification) { create(:online_notification, o: ticket, user_id: agent.id) }
  let!(:subscription) { create(:push_subscription, user: agent) }

  before do
    allow(Service::User::PushSubscription::Deliver).to receive(:execute)
    allow(Rails.logger).to receive(:error)
  end

  it 'delivers the rendered payload to the device' do
    described_class.perform_now(notification, subscription)

    message = OnlineNotification::PushPayload.new(notification).to_h.to_json

    expect(Service::User::PushSubscription::Deliver).to have_received(:execute).with(subscription:, message:)
  end

  context 'when the recipient used Zammad recently, but not actively in the desktop app' do
    {
      'a desktop tab without contact for longer than five minutes' => -> { create(:taskbar, user_id: agent.id, app: 'desktop').update_columns(last_contact: 6.minutes.ago) },
      'a ticket open in the mobile app right now'                  => -> { create(:taskbar, user_id: agent.id, app: 'mobile') },
      'a desktop tab of another agent right now'                   => -> { create(:taskbar, user_id: create(:agent).id, app: 'desktop') },
    }.each do |description, setup|
      context "with #{description}" do
        before { instance_exec(&setup) }

        it 'delivers the push' do
          described_class.perform_now(notification, subscription)

          expect(Service::User::PushSubscription::Deliver).to have_received(:execute)
        end
      end
    end
  end

  context 'when the notification is no longer worth a push' do
    {
      'the recipient lost access to the ticket'   => -> { ticket.update!(group: create(:group)) },
      'the recipient was deactivated'             => -> { agent.update!(active: false) },
      'the notification was seen in the meantime' => -> { notification.update!(seen: true) },
    }.each do |description, change|
      context "when #{description}" do
        before { instance_exec(&change) }

        # Reloaded like the job argument, which is fetched again when the job runs.
        it 'delivers nothing and keeps the subscription', :aggregate_failures do
          expect { described_class.perform_now(notification.reload, subscription) }.not_to change(PushSubscription, :count)

          expect(Service::User::PushSubscription::Deliver).not_to have_received(:execute)
        end
      end
    end

    context 'when the recipient is active in the desktop app' do
      before { create(:taskbar, user_id: agent.id, app: 'desktop') }

      it 'delivers nothing and keeps the subscription', :aggregate_failures do
        expect { described_class.perform_now(notification, subscription) }.not_to change(PushSubscription, :count)

        expect(Service::User::PushSubscription::Deliver).not_to have_received(:execute)
      end
    end

    context 'when the article of the notification was deleted' do
      let(:article)       { create(:ticket_article, ticket:) }
      let!(:notification) { create(:online_notification, o: article, user_id: agent.id) }

      before { article.destroy }

      it 'delivers nothing' do
        described_class.perform_now(notification.reload, subscription)

        expect(Service::User::PushSubscription::Deliver).not_to have_received(:execute)
      end
    end

    context 'with a generated knowledge base answer' do
      let(:translation)   { create(:knowledge_base_answer, :draft).translations.first }
      let!(:notification) { create(:online_notification, o: translation, user_id: agent.id, type_name: 'create') }

      context 'when the recipient can see the answer' do
        let(:agent) { create(:admin, groups: [group]) }

        it 'delivers it' do
          described_class.perform_now(notification.reload, subscription)

          expect(Service::User::PushSubscription::Deliver).to have_received(:execute)
        end
      end

      context 'when the recipient can no longer see the answer' do
        it 'delivers nothing' do
          described_class.perform_now(notification.reload, subscription)

          expect(Service::User::PushSubscription::Deliver).not_to have_received(:execute)
        end
      end
    end

    context 'with a finished bulk action' do
      let!(:notification) { create(:online_notification, :with_bulk_job, user_id: agent.id) }

      it 'delivers it' do
        described_class.perform_now(notification.reload, subscription)

        expect(Service::User::PushSubscription::Deliver).to have_received(:execute)
      end
    end
  end

  context 'when the delivery fails temporarily' do
    before do
      allow(Service::User::PushSubscription::Deliver).to receive(:execute)
        .and_raise(Service::User::PushSubscription::Deliver::TemporaryError, 'push service unavailable')
    end

    it 'retries the delivery to this device' do
      described_class.perform_now(notification, subscription)

      expect(described_class).to have_been_enqueued.with(notification, subscription)
    end

    it 'gives up after the last attempt and logs it', :aggregate_failures do
      perform_enqueued_jobs { described_class.perform_later(notification, subscription) }

      expect(Service::User::PushSubscription::Deliver).to have_received(:execute).exactly(5).times
      expect(Rails.logger).to have_received(:error).with(no_args).once
    end
  end

  context 'when the subscription was removed before the job ran' do
    it 'discards the job' do
      described_class.perform_later(notification, subscription)
      subscription.destroy

      expect { perform_enqueued_jobs }.not_to raise_error
    end
  end
end

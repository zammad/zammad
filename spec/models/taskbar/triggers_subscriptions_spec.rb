# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Taskbar::TriggersSubscriptions, :aggregate_failures, performs_jobs: true do
  let(:ticket)          { create(:ticket) }
  let(:user)            { create(:agent, groups: [ticket.group]) }
  let(:user_other)      { create(:agent, groups: [ticket.group]) }
  let(:taskbar)         { create(:taskbar, :with_ticket, ticket:, user:) }
  let(:related_taskbar) { create(:taskbar, :with_ticket, ticket:, user: user_other) }

  before do
    freeze_time
    related_taskbar.save!
    taskbar.save!
    perform_enqueued_jobs
    travel(1.second)
    allow(Gql::Subscriptions::Ticket::LiveUserUpdates).to receive(:trigger)
    allow(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to receive(:trigger_after_create)
    allow(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to receive(:trigger_after_update)
    allow(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to receive(:trigger_after_destroy)
    allow(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).to receive(:trigger)
  end

  context 'when creating a record' do
    it 'triggers correctly' do
      create(:taskbar)
      expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).once
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to have_received(:trigger_after_create).once
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating prio' do
    it 'triggers correctly' do
      taskbar.prio += 1
      taskbar.save!
      expect(Gql::Subscriptions::Ticket::LiveUserUpdates).not_to have_received(:trigger)
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating active' do
    it 'triggers correctly' do
      taskbar.active = !taskbar.active
      taskbar.save!
      perform_enqueued_jobs
      expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).twice
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating dirty' do
    it 'triggers correctly' do
      taskbar.preferences[:dirty] = !taskbar.preferences[:dirty]
      taskbar.save!
      perform_enqueued_jobs
      expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).twice
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to have_received(:trigger_after_update).once
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating last_contact_at' do
    it 'triggers correctly' do
      taskbar.touch_last_contact!
      perform_enqueued_jobs
      expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).exactly(1) # only for related_taskbar
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating state' do
    context 'with desktop app' do
      it 'triggers correctly' do
        taskbar.state = { 'body' => 'test' }
        taskbar.save!
        perform_enqueued_jobs
        expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).exactly(2)
        expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).to have_received(:trigger).once
      end
    end

    context 'with mobile app' do
      let(:taskbar) { create(:taskbar, :with_ticket, ticket:, user:, app: 'mobile') }

      it 'triggers correctly' do
        taskbar.state = { 'body' => 'test' }
        taskbar.save!
        perform_enqueued_jobs
        expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).exactly(2)
        expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
        expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
      end
    end
  end

  context 'when deleting the record' do
    it 'triggers correctly' do
      taskbar.destroy!
      perform_enqueued_jobs
      expect(Gql::Subscriptions::Ticket::LiveUserUpdates).to have_received(:trigger).once # only for related_taskbar
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to have_received(:trigger_after_destroy)
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end
end

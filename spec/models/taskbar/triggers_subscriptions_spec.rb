# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Taskbar::TriggersSubscriptions, :aggregate_failures do
  let(:taskbar)         { create(:taskbar, user: create(:user)) }
  let(:related_taskbar) { create(:taskbar, key: taskbar.key, user: create(:user)) }

  gqs = Gql::Subscriptions
  gqs_uc = gqs::User::Current

  before do
    freeze_time
    related_taskbar.save!
    taskbar.save!
    travel(1.second)
    allow(gqs::TicketLiveUserUpdates).to receive(:trigger)
    allow(gqs_uc::TaskbarItemUpdates).to receive(:trigger_after_create)
    allow(gqs_uc::TaskbarItemUpdates).to receive(:trigger_after_update)
    allow(gqs_uc::TaskbarItemUpdates).to receive(:trigger_after_destroy)
    allow(gqs_uc::TaskbarItemStateUpdates).to receive(:trigger)
  end

  context 'when creating a record' do
    it 'triggers correctly' do
      create(:taskbar)
      expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).once
      expect(gqs_uc::TaskbarItemUpdates).to have_received(:trigger_after_create).once
      expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating prio' do
    it 'triggers correctly' do
      taskbar.prio += 1
      taskbar.save!
      expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).exactly(2)
      expect(gqs_uc::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
      expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating active' do
    it 'triggers correctly' do
      taskbar.active = !taskbar.active
      taskbar.save!
      expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).twice
      expect(gqs_uc::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
      expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating dirty' do
    it 'triggers correctly' do
      taskbar.preferences[:dirty] = !taskbar.preferences[:dirty]
      taskbar.save!
      expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).twice
      expect(gqs_uc::TaskbarItemUpdates).to have_received(:trigger_after_update).once
      expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating last_contact_at' do
    it 'triggers correctly' do
      taskbar.touch_last_contact!
      expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).exactly(1) # only for related_taskbar
      expect(gqs_uc::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
      expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  context 'when updating state' do
    context 'with desktop app' do
      it 'triggers correctly' do
        taskbar.state = { 'body' => 'test' }
        taskbar.save!
        expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).exactly(2)
        expect(gqs_uc::TaskbarItemUpdates).to have_received(:trigger_after_update).once # only for taskbar
        expect(gqs_uc::TaskbarItemStateUpdates).to have_received(:trigger).once
      end
    end

    context 'with mobile app' do
      let(:taskbar) { create(:taskbar, app: 'mobile') }

      it 'triggers correctly' do
        taskbar.state = { 'body' => 'test' }
        taskbar.save!
        expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).exactly(2)
        expect(gqs_uc::TaskbarItemUpdates).not_to have_received(:trigger_after_update)
        expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
      end
    end
  end

  context 'when deleting the record' do
    it 'triggers correctly' do
      taskbar.destroy!
      expect(gqs::TicketLiveUserUpdates).to have_received(:trigger).once # only for related_taskbar
      expect(gqs_uc::TaskbarItemUpdates).to have_received(:trigger_after_destroy)
      expect(gqs_uc::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TaskbarUpdateTriggerSubscriptionsJob, aggregate_failures: true, type: :job do

  let(:ticket) { create(:ticket) }

  let(:taskbar_key) { "Ticket-#{ticket.id}" }

  let!(:taskbar_owner)  { create(:agent, groups: [ticket.group]) }
  let!(:taskbar_other)  { create(:agent, groups: [ticket.group]) }
  let!(:different_user) { create(:agent, groups: [ticket.group]) }

  let!(:taskbar_1) { create(:taskbar, :with_ticket, ticket:, app: 'desktop', user: taskbar_owner, notify: false) }
  let!(:taskbar_2) { create(:taskbar, :with_ticket, ticket:, app: 'desktop', user: taskbar_other, notify: false) }

  current_taskbar_item_updates = Gql::Subscriptions::User::Current::TaskbarItemUpdates

  before do
    allow(current_taskbar_item_updates).to receive(:trigger_after_update)
  end

  describe '#perform' do
    context 'when updated by a different user' do
      it 'sets notify and triggers subscription for related taskbars' do
        # Update ticket with a different user
        ticket.update!(updated_by_id: different_user.id)

        described_class.perform_now(taskbar_key, ticket, [])

        expect(taskbar_1.reload.notify).to be(true)
        expect(taskbar_2.reload.notify).to be(true)
        expect(current_taskbar_item_updates).to have_received(:trigger_after_update).twice
      end
    end

    context 'when group_id changed' do
      it 'manually triggers subscription without changing notify' do
        # Ensure notify path does not run by setting same updater as taskbar user
        # Since taskbar.user_id is the "creator" in this context
        ticket.update!(updated_by_id: taskbar_1.user_id)

        described_class.perform_now(taskbar_key, ticket, ['group_id'])

        expect(taskbar_1.reload.notify).to be(false)
        expect(taskbar_2.reload.notify).to be(true)
        expect(current_taskbar_item_updates).to have_received(:trigger_after_update).twice
      end
    end
  end
end

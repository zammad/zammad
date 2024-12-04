# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Taskbar::List' do
  let(:user) { create(:user) }

  describe '.reorder_list' do
    let(:user)          { create(:user) }
    let(:taskbar_1)     { create(:taskbar, user:) }
    let(:taskbar_2)     { create(:taskbar, user:) }
    let(:taskbar_3)     { create(:taskbar, user:) }
    let(:taskbar_other) { create(:taskbar) }

    let(:target_order) do
      [
        { id: taskbar_1.id, prio: 3 },
        { id: taskbar_2.id, prio: 1 },
        { id: taskbar_3.id, prio: 2 },
      ]
    end

    before { taskbar_1 && taskbar_2 && taskbar_3 }

    it 'update order with given details' do
      described_class.reorder_list(user, target_order)

      scope = TaskbarPolicy::Scope.new(user, Taskbar)

      expect(scope.resolve).to eq([taskbar_2, taskbar_3, taskbar_1])
    end

    it 'works if non-existant ID included' do
      target_order.push({ id: 1234, prio: 1234 })

      described_class.reorder_list(user, target_order)

      scope = TaskbarPolicy::Scope.new(user, Taskbar)

      expect(scope.resolve).to eq([taskbar_2, taskbar_3, taskbar_1])
    end

    it 'ignores inaccessible taskbar' do
      test_prio = 1234

      target_order.push({ id: taskbar_other.id, prio: test_prio })
      described_class.reorder_list(user, target_order)

      expect(taskbar_other.reload).not_to have_attributes(prio: test_prio)
    end

    it 'trigger subscription after updating' do
      allow(described_class).to receive(:trigger_list_update)

      described_class.reorder_list(user, target_order)

      expect(described_class).to have_received(:trigger_list_update).with(user, 'desktop')
    end

    it 'do not trigger other subscriptions', aggregate_failures: true do
      allow(Gql::Subscriptions::TicketLiveUserUpdates).to receive(:trigger)
      allow(Gql::Subscriptions::User::Current::TaskbarItemUpdates).to receive(:trigger)
      allow(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).to receive(:trigger)

      described_class.reorder_list(user, target_order)

      expect(Gql::Subscriptions::TicketLiveUserUpdates).not_to have_received(:trigger)
      expect(Gql::Subscriptions::User::Current::TaskbarItemUpdates).not_to have_received(:trigger)
      expect(Gql::Subscriptions::User::Current::TaskbarItemStateUpdates).not_to have_received(:trigger)
    end
  end

  describe '.trigger_list_update' do
    it 'calls subscription with given params' do
      allow(Gql::Subscriptions::User::Current::TaskbarItem::ListUpdates).to receive(:trigger)

      described_class.trigger_list_update(user, 'test')

      expect(Gql::Subscriptions::User::Current::TaskbarItem::ListUpdates)
        .to have_received(:trigger)
        .with(nil, arguments: { user_id: user.to_global_id.to_s, app: 'test' })
    end
  end
end

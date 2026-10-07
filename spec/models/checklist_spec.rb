# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist, :aggregate_failures, current_user_id: 1, type: :model do
  let(:ticket)    { create(:ticket) }
  let(:checklist) { create(:checklist, item_count: 0, ticket:) }

  describe 'validations' do
    context 'with valid attributes' do
      it 'succeeds creation' do
        expect(create(:checklist)).to be_persisted
      end
    end
  end

  describe '#complete' do
    it 'returns zero if list is empty' do
      expect(checklist.complete).to be_zero
    end

    it 'returns count of completed items' do
      3.times { create(:checklist_item, checklist:, checked: true) }
      2.times { create(:checklist_item, checklist:, checked: false) }

      expect(checklist.complete).to be 3
    end
  end

  describe '#completed?' do
    it 'returns true if list is empty' do
      expect(checklist).to be_completed
    end

    it 'returns true if all completed' do
      create(:checklist_item, checklist:, checked: true)
      create(:checklist_item, checklist:, checked: true)

      expect(checklist).to be_completed
    end

    it 'returns false if some incomplete' do
      create(:checklist_item, checklist:, checked: true)
      create(:checklist_item, checklist:, checked: false)

      expect(checklist).not_to be_completed
    end
  end

  describe '#incomplete' do
    it 'returns count of completed items' do
      3.times { create(:checklist_item, checklist:, checked: true) }
      2.times { create(:checklist_item, checklist:, checked: false) }

      expect(checklist.incomplete).to be 2
    end
  end

  describe '#total' do
    it 'returns count of completed items' do
      3.times { create(:checklist_item, checklist:, checked: true) }
      2.times { create(:checklist_item, checklist:, checked: false) }

      expect(checklist.total).to be 5
    end
  end

  describe '#update_ticket' do
    it 'touches ticket when updating the checklist' do
      checklist

      travel 10.minutes

      expect { checklist.update!(name: 'abc') }
        .to change { checklist.ticket.updated_at }
    end

    it 'touches ticket when destroying the checklist' do
      checklist

      travel 10.minutes

      expect { checklist.destroy! }
        .to change { checklist.ticket.updated_at }
    end

    it 'does not raise erorrs when ticket is destroyed' do
      checklist

      expect { checklist.ticket.destroy! }
        .not_to raise_error
    end
  end

  describe '#report_checklist_existing_change' do
    let(:reported_changes) do
      EventBuffer.list('transaction').filter_map { |event| event[:changes] if event[:object] == 'Ticket' && event[:id] == ticket.id }
    end

    before do
      checklist
      TransactionDispatcher.reset
    end

    it 'reports the checklist becoming non-empty' do
      create(:checklist_item, checklist:)

      expect(reported_changes).to include('checklist_existing' => [false, true])
    end

    it 'reports the checklist becoming empty' do
      item = create(:checklist_item, checklist:)
      TransactionDispatcher.reset

      item.destroy!

      expect(reported_changes).to include('checklist_existing' => [true, false])
    end

    it 'reports the removal of a checklist with items' do
      create(:checklist_item, checklist:)
      TransactionDispatcher.reset

      checklist.destroy!

      expect(reported_changes).to include('checklist_existing' => [true, false])
    end

    it 'reports nothing while the checklist keeps items' do
      item = create(:checklist_item, checklist:)
      TransactionDispatcher.reset

      item.update!(checked: true)
      create(:checklist_item, checklist:)

      expect(reported_changes).to be_empty
    end

    context 'when import mode is on' do
      before { Setting.set('import_mode', true) }

      it 'reports nothing' do
        create(:checklist_item, checklist:)

        expect(reported_changes).to be_empty
      end
    end
  end

  describe '.ticket_closed?' do
    it 'open ticket is not closed' do
      ticket = create(:ticket, state_name: 'open')
      expect(described_class).not_to be_ticket_closed(ticket)
    end

    it 'new ticket is not closed' do
      ticket = create(:ticket, state_name: 'new')
      expect(described_class).not_to be_ticket_closed(ticket)
    end

    it 'closed ticket is closed' do
      ticket = create(:ticket, state_name: 'closed')
      expect(described_class).to be_ticket_closed(ticket)
    end

    it 'merged ticket is closed' do
      ticket = create(:ticket, state_name: 'merged')
      expect(described_class).to be_ticket_closed(ticket)
    end
  end

  describe '.create_fresh!' do
    it 'creates a fresh checklist' do
      checklist = described_class.create_fresh!(ticket)

      expect(checklist.items).to contain_exactly(have_attributes(id: be_present, text: be_blank))
    end

    it 'does not create a checklist if the ticket already has one' do
      checklist

      expect { described_class.create_fresh!(ticket) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: This ticket already has a checklist.'
        )
    end
  end

  describe '.create_from_template!' do
    let(:template) { create(:checklist_template) }

    it 'creates a checklist' do
      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template).to be_persisted
    end

    it 'copies entries in order' do
      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template.sorted_items.map(&:text)).to eq(template.items.map(&:text))
    end

    it 'copies custom-ordered entries in order' do
      sorted_items = template.items.shuffle

      template.update!(sorted_item_ids: sorted_items.map(&:id))

      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template.sorted_items.map(&:text)).to eq(sorted_items.map(&:text))
    end

    it 'copies entries with initial_clone flag' do
      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template.items).to all(have_attributes(initial_clone: true))
    end

    it 'raises an error if template is inactive' do
      template.update! active: false

      expect { described_class.create_from_template!(ticket, template) }
        .to raise_error(
          Exceptions::UnprocessableContent,
          'Checklist template must be active to use as a checklist starting point.'
        )
    end

    it 'does not create a checklist if the ticket already has one' do
      checklist

      expect { described_class.create_from_template!(ticket, template) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: This ticket already has a checklist.'
        )
    end

    # Two requests for one ticket start from their own copies of it, loaded before either writes.
    #   Replayed in sequence, the second request holds exactly the stale state the race leaves it with.
    it 'does not create a checklist if another request created one after this one loaded the ticket' do
      other_ticket = Ticket.find(ticket.id)

      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect { described_class.create_from_template!(other_ticket, template) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: This ticket already has a checklist.'
        )
      expect(ticket.reload.checklist).to eq(checklist_from_template)
      expect(described_class.where.missing(:ticket)).to be_empty
    end

    it 'creates a checklist if another request removed the one this one loaded the ticket with' do
      checklist
      other_ticket = Ticket.find(ticket.id)

      checklist.destroy!

      checklist_from_template = described_class.create_from_template!(other_ticket, template)

      expect(ticket.reload.checklist).to eq(checklist_from_template)
      expect(described_class.where.missing(:ticket)).to be_empty
    end
  end

  describe '.add_from_template!' do
    let(:template) { create(:checklist_template, items: ['Template item 1', 'Template item 2']) }

    context 'when the ticket has no checklist' do
      it 'creates a checklist from the template' do
        checklist_from_template = described_class.add_from_template!(ticket, template)

        expect(checklist_from_template).to have_attributes(name: template.name, ticket: ticket)
        expect(checklist_from_template.sorted_items.map(&:text)).to eq(['Template item 1', 'Template item 2'])
      end

      it 'raises an error if template is inactive' do
        template.update! active: false

        expect { described_class.add_from_template!(ticket, template) }
          .to raise_error(Exceptions::UnprocessableContent, 'Checklist template must be active to use as a checklist starting point.')
        expect(ticket.reload.checklist).to be_nil
      end

      # The explicit transaction stands in for a job slice or a ticket update that rescues the error
      #   and commits; the test transaction cannot, as it is not joinable and would turn the model's own
      #   transaction into a savepoint anyway. Without the savepoint the checklist written before the
      #   ticket rejected it would be kept. The refreshed ticket carries no in-memory changes, so its
      #   rejection is injected.
      it 'writes nothing when the ticket fails its own validation while the checklist is written' do
        allow(ticket).to receive(:valid?) do
          ticket.errors.clear
          ticket.errors.add(:base, 'rejected the checklist')
          false
        end

        ActiveRecord::Base.transaction do
          expect { described_class.add_from_template!(ticket, template) }
            .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: rejected the checklist')
        end

        expect(ticket.reload.checklist).to be_nil
        expect(described_class.where.missing(:ticket)).to be_empty
        expect(Checklist::Item.where(checklist: described_class.where.missing(:ticket))).to be_empty
      end

      # Two automation runs for one ticket start from their own copies of it, loaded before either
      #   writes. Replaying such a pair in sequence hands the second run exactly the stale state the
      #   race leaves it with, so this fails without the locked re-read and needs no threads to do so.
      it 'appends to the checklist another run created after this one loaded the ticket' do
        other_ticket = Ticket.find(ticket.id).tap(&:checklist)

        checklist_from_template = described_class.add_from_template!(ticket, template)
        described_class.add_from_template!(other_ticket, template)

        expect(ticket.reload.checklist).to eq(checklist_from_template)
        expect(checklist_from_template.reload.sorted_items.map(&:text))
          .to eq(['Template item 1', 'Template item 2'] * 2)
      end

      it 'creates a checklist when another run removed the one this one loaded the ticket with' do
        checklist
        other_ticket = Ticket.find(ticket.id)

        checklist.destroy!

        checklist_from_template = described_class.add_from_template!(other_ticket, template)

        expect(ticket.reload.checklist).to eq(checklist_from_template)
        expect(checklist_from_template.sorted_items.map(&:text)).to eq(['Template item 1', 'Template item 2'])
      end
    end

    context 'when the ticket has a checklist' do
      let(:checklist)      { create(:checklist, name: 'Existing checklist', item_count: 2, ticket:) }
      let(:existing_items) { checklist.sorted_items.to_a }

      before { existing_items }

      it 'appends the template items after the existing ones in template order' do
        described_class.add_from_template!(ticket, template)

        expect(checklist.reload.sorted_items.map(&:text))
          .to eq(existing_items.map(&:text) + ['Template item 1', 'Template item 2'])
      end

      it 'appends custom-ordered template items in template order' do
        sorted_template_items = template.items.reverse

        template.update!(sorted_item_ids: sorted_template_items.map(&:id))

        described_class.add_from_template!(ticket, template)

        expect(checklist.reload.sorted_items.map(&:text))
          .to eq(existing_items.map(&:text) + sorted_template_items.map(&:text))
      end

      it 'keeps the checklist, its name and its existing items unchanged' do
        expect { described_class.add_from_template!(ticket, template) }
          .to not_change { ticket.reload.checklist_id }
          .and not_change { checklist.reload.name }
          .and not_change { Checklist::Item.where(id: existing_items).reorder(:id).map(&:attributes) }
      end

      it 'stores every item id as a string' do
        described_class.add_from_template!(ticket, template)

        expect(checklist.reload.sorted_item_ids).to eq(checklist.items.reorder(:id).map { |item| item.id.to_s })
      end

      it 'returns the existing checklist' do
        expect(described_class.add_from_template!(ticket, template)).to eq(checklist)
      end

      # Same replay as above: the second run holds the checklist as it was before the first one wrote.
      it 'appends after the items another run added since this one loaded the checklist' do
        other_ticket = Ticket.find(ticket.id).tap(&:checklist)

        described_class.add_from_template!(ticket, template)
        described_class.add_from_template!(other_ticket, template)

        expect(checklist.reload.sorted_items.map(&:text))
          .to eq(existing_items.map(&:text) + (['Template item 1', 'Template item 2'] * 2))
      end

      it 'updates the ticket and triggers the checklist subscription once' do
        ticket_updates = 0
        callback       = ->(*, payload) { ticket_updates += 1 if payload[:sql].start_with?('UPDATE "tickets"') }

        allow(Gql::Subscriptions::Ticket::ChecklistUpdates).to receive(:trigger).and_call_original

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          described_class.add_from_template!(ticket, template)
        end

        expect(ticket_updates).to eq(1)
        expect(Gql::Subscriptions::Ticket::ChecklistUpdates).to have_received(:trigger).once
      end

      it 'writes a created history entry related to the ticket for each appended item' do
        described_class.add_from_template!(ticket, template)

        appended_items = checklist.reload.sorted_items.last(2)

        expect(History.where(o_id: appended_items.map(&:id), history_object_id: History::Object.lookup(name: 'Checklist::Item').id))
          .to contain_exactly(
            have_attributes(history_type_id: History::Type.lookup(name: 'created').id, related_o_id: ticket.id, value_to: 'Template item 1'),
            have_attributes(history_type_id: History::Type.lookup(name: 'created').id, related_o_id: ticket.id, value_to: 'Template item 2'),
          )
      end

      it 'raises an error if template is inactive' do
        template.update! active: false

        expect { described_class.add_from_template!(ticket, template) }
          .to raise_error(Exceptions::UnprocessableContent, 'Checklist template must be active to use as a checklist starting point.')
        expect(checklist.reload.items.count).to eq(2)
      end

      it 'fails without a current user' do
        UserInfo.current_user_id = nil

        expect { described_class.add_from_template!(ticket, template) }
          .to raise_error(ActiveRecord::RecordInvalid, %r{Created by must exist})
      end

      context 'when the template items do not fit into the item limit' do
        let(:template) { create(:checklist_template, item_count: 99) }

        it 'raises an error' do
          expect { described_class.add_from_template!(ticket, template) }
            .to raise_error(Exceptions::UnprocessableContent, 'Checklist items are limited to 100 items per checklist.')
        end

        # A trigger runs inside an outer transaction which the method's own transaction joins, so a
        #   rescued error there rolls nothing back. Reproduce that to prove no item is written before the guard.
        it 'writes nothing even when the error is rescued inside an outer transaction' do
          ActiveRecord::Base.transaction do
            described_class.add_from_template!(ticket, template)
          rescue Exceptions::UnprocessableContent
            nil
          end

          expect(checklist.reload.items.count).to eq(2)
        end
      end
    end

    # Automation holds the ticket row before it reaches the checklist row, so a manual write that takes
    #   them the other way round deadlocks with it. Each side needs its own connection: transactional
    #   tests pin every thread to one connection and a sequential replay never holds two rows at once,
    #   so neither can show the cycle. The manual write is paused behind its checklist row until the
    #   template application on the second connection waits for a lock, then both have to finish.
    context 'when a manual checklist write overlaps template application', :ensure_threads_exited, performs_jobs: true do
      self.use_transactional_tests = false

      let(:customer)  { create(:customer) }
      let(:ticket)    { create(:ticket, group: Group.first, customer:) }
      let(:checklist) { create(:checklist, name: 'Existing checklist', item_count: 0, ticket:) }
      let(:item)      { create(:checklist_item, checklist:, text: 'Existing item') }

      before { item }

      # Nothing is rolled back here, so the records and what they left behind are removed by hand.
      after do
        ticket.reload.destroy!
        template.destroy!
        customer.destroy!
        History.where(related_history_object_id: History::Object.lookup(name: 'Ticket').id, related_o_id: ticket.id).delete_all
        clear_jobs
      end

      # paused_after names the statement with which the manual write takes its checklist row: the
      #   UPDATE of a plain save, or the SELECT … FOR UPDATE of a with_lock caller.
      def apply_template_while_holding_checklist_row(paused_after: %r{\AUPDATE "checklists"}, &)
        automation = nil
        pids       = Queue.new

        pause_manual_write = lambda do |*, payload|
          next if automation || !payload[:sql].match?(paused_after)

          automation = Thread.new do
            UserInfo.current_user_id = 1

            ActiveRecord::Base.connection_pool.with_connection do |connection|
              pids << connection.select_value('SELECT pg_backend_pid()')
              described_class.add_from_template!(Ticket.find(ticket.id), template)
            end
          end

          wait_until_waiting_for_lock(pids.pop)
        end

        ActiveSupport::Notifications.subscribed(pause_manual_write, 'sql.active_record', &)
      ensure
        automation&.join
      end

      def wait_until_waiting_for_lock(pid)
        deadline = 10.seconds.from_now
        query    = ActiveRecord::Base.sanitize_sql_array(['SELECT wait_event_type FROM pg_stat_activity WHERE pid = ?', pid])

        until ActiveRecord::Base.connection.select_value(query) == 'Lock'
          raise 'The template application never waited for a lock.' if Time.current > deadline

          sleep 0.01
        end
      end

      it 'renames the checklist and appends the template items' do
        apply_template_while_holding_checklist_row { checklist.update!(name: 'Renamed checklist') }

        expect(checklist.reload).to have_attributes(name: 'Renamed checklist')
        expect(checklist.sorted_items.map(&:text)).to eq(['Existing item', 'Template item 1', 'Template item 2'])
      end

      it 'edits the item and appends the template items' do
        apply_template_while_holding_checklist_row { item.update!(text: 'Edited item') }

        expect(checklist.reload.sorted_items.map(&:text)).to eq(['Edited item', 'Template item 1', 'Template item 2'])
      end

      # The legacy checklist endpoint takes the checklist row through with_lock ahead of every callback,
      #   so the manual write is paused right behind that row lock.
      it 'renames the checklist behind with_lock and appends the template items' do
        apply_template_while_holding_checklist_row(paused_after: %r{FROM "checklists" .* FOR UPDATE\z}) do
          checklist.with_lock { checklist.update!(name: 'Renamed checklist') }
        end

        expect(checklist.reload).to have_attributes(name: 'Renamed checklist')
        expect(checklist.sorted_items.map(&:text)).to eq(['Existing item', 'Template item 1', 'Template item 2'])
      end
    end
  end

  describe '.tickets_referencing' do
    let(:ticket)                 { create(:ticket, group:) }
    let(:other_ticket)           { create(:ticket, group:) }
    let(:inaccessible_ticket)    { create(:ticket) }
    let(:checklist)              { create(:checklist) }
    let(:other_checklist)        { create(:checklist) }
    let(:inaccessible_checklist) { create(:checklist, ticket: inaccessible_ticket) }
    let(:user)                   { create(:agent, groups: [group]) }
    let(:group)                  { create(:group) }

    before do
      other_checklist.items.create! ticket: other_ticket
    end

    it 'returns scope to work on' do
      expect(described_class.tickets_referencing(ticket)).to be_a(ActiveRecord::Relation)
    end

    it 'if user is given returns scope to work on' do
      expect(described_class.tickets_referencing(ticket, user)).to be_a(ActiveRecord::Relation)
    end

    context 'when ticket never referenced' do
      it 'returns 0 references' do
        expect(described_class.tickets_referencing(ticket)).to be_blank
      end
    end

    context 'when ticket is referenced' do
      before do
        checklist.items.create! ticket: ticket
      end

      it 'returns 1 reference' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket)
      end
    end

    context 'when ticket is referenced in multiple checklists' do
      before do
        checklist.items.create! ticket: ticket
        other_checklist.items.create! ticket: ticket
      end

      it 'returns 2 references' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket, other_checklist.ticket)
      end
    end

    context 'when ticket is referenced multiple times in the same checklist' do
      before do
        3.times { checklist.items.create! ticket: ticket }
      end

      it 'returns 2 references' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket)
      end
    end

    context 'with inaccessible reference' do
      before do
        checklist.update! ticket: other_ticket
        checklist.items.create! ticket: ticket
        inaccessible_checklist.items.create! ticket: ticket
      end

      it 'returns tickets accessible to given user only' do
        expect(described_class.tickets_referencing(ticket, user))
          .to contain_exactly(checklist.ticket)
      end

      it 'returns all tickets accessible if no user given' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket, inaccessible_checklist.ticket)
      end
    end
  end

  describe '.search_index_attribute_lookup' do
    subject(:checklist) { create(:checklist, name: 'some name') }

    it 'verify name attribute' do
      expect(checklist.search_index_attribute_lookup['name']).to eq checklist.name
    end

    it 'verify items attribute' do
      expect(checklist.search_index_attribute_lookup['items']).not_to eq []
    end

    it 'verify items[0].count' do
      expect(checklist.search_index_attribute_lookup['items'].count).to eq checklist.items.count
    end

    it 'verify items[0].text attribute' do
      expect(checklist.search_index_attribute_lookup['items'][0]['text']).to eq checklist.items[0].text
    end
  end

end

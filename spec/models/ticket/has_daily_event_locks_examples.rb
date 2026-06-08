# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Ticket::HasDailyEventLocks' do
  context 'when daily locks exist' do
    let(:ticket)                              { create(:ticket) }
    let(:other_ticket)                        { create(:ticket) }
    let!(:escalation_lock)                    { create(:ticket_daily_event_lock, lock_activator: 'escalation', ticket: ticket, related_object: create(:user)) }
    let!(:escalation_warning_lock)            { create(:ticket_daily_event_lock, lock_activator: 'escalation_warning', ticket: ticket, related_object: create(:trigger)) }
    let!(:escalation_lock_other_ticket)       { create(:ticket_daily_event_lock, lock_activator: 'escalation', ticket: other_ticket) }
    let!(:reminder_reached_lock)              { create(:ticket_daily_event_lock, lock_activator: 'reminder_reached', ticket: ticket) }
    let!(:reminder_reached_lock_other_ticket) { create(:ticket_daily_event_lock, lock_activator: 'reminder_reached', ticket: other_ticket) }

    context 'when escalation_at changes' do
      it 'cleans up only escalation and escalation warning daily locks for that ticket' do
        ticket.update(escalation_at: 1.hour.from_now)

        expect(Ticket::DailyEventLock.all)
          .to contain_exactly(escalation_lock_other_ticket, reminder_reached_lock, reminder_reached_lock_other_ticket)
      end
    end

    context 'when pending_time changes' do
      it 'cleans up only reminder reached daily locks for that ticket' do
        ticket.update(pending_time: 1.hour.from_now)

        expect(Ticket::DailyEventLock.all)
          .to contain_exactly(escalation_lock, escalation_warning_lock, escalation_lock_other_ticket, reminder_reached_lock_other_ticket)
      end
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Escalation do
  let(:instance) { described_class.new ticket, force: force }
  let(:instance_with_history) { described_class.new ticket_with_history, force: force }
  let(:ticket)   { create(:ticket) }
  let(:force)    { false }
  let(:sla)      { nil }
  let(:sla_247)  { create(:sla, :condition_blank, first_response_time: 60, update_time: 60, solution_time: 75, calendar: create(:calendar, :'24/7')) }
  let(:calendar) { nil }
  let(:ticket_with_history) do
    freeze_time
    ticket = create(:ticket)
    ticket.update! state: Ticket::State.lookup(name: 'new')
    travel 1.hour
    ticket.update! state: Ticket::State.lookup(name: 'open')
    travel 30.minutes
    ticket.update! state: Ticket::State.lookup(name: 'pending close')
    travel 30.minutes
    ticket.update! state: Ticket::State.lookup(name: 'closed'), close_at: Time.current
    ticket
  end

  let(:open_ticket_with_history) do
    freeze_time
    article = create(:ticket_article, :inbound_email)

    travel 10.minutes
    article.ticket.update! state: Ticket::State.lookup(name: 'pending close')
    travel 10.minutes
    article.ticket.update! state: Ticket::State.lookup(name: 'open')

    article.ticket
  end

  describe '#preferences' do
    it { expect(instance.preferences).to be_a Escalation::TicketPreferences }
  end

  describe '#escalation_disabled?' do
    it 'true when ticket is not open' do
      ticket.update! state: Ticket::State.lookup(name: 'pending close')
      expect(instance).to be_escalation_disabled
    end

    it 'false when ticket is open' do
      expect(instance).not_to be_escalation_disabled
    end
  end

  describe '#calculatable?' do
    it 'false when ticket is not open' do
      ticket.update! state: Ticket::State.lookup(name: 'pending close')
      expect(instance).not_to be_calculatable
    end

    it 'true when ticket is open' do
      expect(instance).to be_calculatable
    end

    # https://github.com/zammad/zammad/issues/2579
    it 'true when ticket was just closed' do
      ticket
      travel 30.minutes

      without_update_escalation_information_callback { ticket.update close_at: Time.current, state: Ticket::State.lookup(name: 'closed') }

      expect(instance).to be_calculatable
    end

    it 'true when response to ticket comes while ticket has pending reminder' do
      ticket.update(state: Ticket::State.find_by(name: 'pending reminder'))

      without_update_escalation_information_callback { create(:'ticket/article', :outbound_email, ticket: ticket) }

      expect(instance).to be_calculatable
    end
  end

  describe '#calculate' do
    it 'works and updates' do
      ticket
      sla_247
      expect { instance.calculate }.to change(ticket, :has_changes_to_save?).to(true)
    end

    it 'exit early when escalation is disabled' do
      allow(instance).to receive(:escalation_disabled?).and_return(true)
      allow(instance).to receive(:calendar) # next method called after checking escalation state
      instance.calculate
      expect(instance).not_to have_received(:calendar)
    end

    it 'recalculate when escalation is disabled but it is forced' do
      instance_forced = described_class.new ticket, force: true
      allow(instance_forced).to receive(:escalation_disabled?).and_return(true)
      allow(instance_forced).to receive(:calendar) # next method called after checking escalation state
      instance_forced.calculate
      expect(instance_forced).to have_received(:calendar)
    end

    it 'no calendar is early exit' do
      allow(instance).to receive(:calendar).and_return(nil)
      allow(instance.preferences).to receive(:any_changes?) # next method after the check
      instance.calculate
      expect(instance.preferences).not_to have_received(:any_changes?)
    end

    it 'no calendar resets' do
      allow(instance).to receive(:calendar).and_return(nil)
      allow(instance).to receive(:forced?).and_return(true)
      allow(instance).to receive(:calculate_no_calendar)
      instance.calculate
      expect(instance).to have_received(:calculate_no_calendar)
    end

    context 'with SLA 24/7' do
      before { sla_247 }

      it 'forces recalculation when SLA touched' do
        allow(instance.preferences).to receive(:sla_changed?).and_return(true)
        allow(instance).to receive(:force!)
        instance.calculate

        expect(instance).to have_received(:force!)
      end

      it 'calculates when ticket was touched in a related manner' do
        allow(instance.preferences).to receive(:any_changes?).and_return(true)
        allow(instance).to receive(:update_escalations)
        instance.calculate
        expect(instance).to have_received(:update_escalations)
      end

      it 'skips calculating escalation times when ticket was not touched in a related manner' do
        allow(instance.preferences).to receive(:any_changes?).and_return(false)
        allow(instance).to receive(:update_escalations)
        instance.calculate
        expect(instance).not_to have_received(:update_escalations)
      end

      it 'calculates statistics when ticket was touched in a related manner' do
        allow(instance.preferences).to receive(:any_changes?).and_return(true)
        allow(instance).to receive(:update_statistics)
        instance.calculate
        expect(instance).to have_received(:update_statistics)
      end

      it 'skips calculating statistics when ticket was not touched in a related manner' do
        allow(instance.preferences).to receive(:any_changes?).and_return(false)
        allow(instance).to receive(:update_statistics)
        instance.calculate
        expect(instance).not_to have_received(:update_statistics)
      end

      it 'setting #first_response_at does not nullify other escalations' do
        ticket.update! first_response_at: 30.minutes.from_now
        expect(ticket.reload.close_escalation_at).not_to be_nil
      end

      it 'setting ticket to non-escalatable state clears #escalation_at' do
        ticket.update! state: Ticket::State.lookup(name: 'closed')
        expect(ticket.escalation_at).to be_nil
      end

      # https://github.com/zammad/zammad/issues/2579
      it 'calculates closing statistics on closing ticket' do
        ticket

        travel 30.minutes

        without_update_escalation_information_callback { ticket.update close_at: Time.current, state: Ticket::State.lookup(name: 'closed') }

        expect { instance.calculate }.to change(ticket, :close_in_min).from(nil)
      end
    end
  end

  describe '#force!' do
    it 'sets forced? to true' do
      expect { instance.send(:force!) }.to change(instance, :forced?).from(false).to(true)
    end
  end

  describe 'calculate_not_calculatable' do
    it 'sets escalation dates to nil' do
      sla_247
      open_ticket_with_history
      instance = described_class.new open_ticket_with_history
      instance.calculate_not_calculatable
      expect(open_ticket_with_history).to have_attributes(escalation_at: nil, first_response_escalation_at: nil, update_escalation_at: nil, close_escalation_at: nil)
    end
  end

  describe '#sla' do
    it 'returns SLA when it exists' do
      sla_247
      expect(instance.sla).to be_a(Sla)
    end

    it 'returns nil when no SLA' do
      expect(instance.sla).to be_nil
    end
  end

  describe '#calendar' do
    it 'returns calendar when it exists' do
      sla_247
      expect(instance.calendar).to be_a(Calendar)
    end

    it 'returns nil when no calendar' do
      expect(instance.calendar).to be_nil
    end
  end

  describe '#forced?' do
    it 'true when given true' do
      instance = described_class.new ticket, force: true
      expect(instance).to be_forced
    end

    it 'false when given false' do
      instance = described_class.new ticket, force: false
      expect(instance).not_to be_forced
    end

    it 'false when given nil' do
      instance = described_class.new ticket, force: nil
      expect(instance).not_to be_forced
    end
  end

  describe '#update_escalations' do
    it 'sets escalation times' do
      instance = described_class.new open_ticket_with_history
      sla_247
      expect { instance.update_escalations }
        .to change(open_ticket_with_history, :escalation_at).from(nil)
    end

    # https://github.com/zammad/zammad/issues/3140
    it 'agent follow up does not set #update_escalation_at' do
      sla_247
      ticket
      create(:ticket_article, :outbound_email, ticket: ticket)

      expect(ticket.reload.update_escalation_at).to be_nil
    end

    # https://github.com/zammad/zammad/issues/3140
    it 'customer contact sets #update_escalation_at' do
      sla_247
      ticket
      create(:ticket_article, :inbound_email, ticket: ticket)

      expect(ticket.reload.update_escalation_at).to be_a(Time)
    end

    context 'with ticket with sla and customer enquiry' do
      before do
        sla_247
        ticket

        travel 10.minutes

        create(:ticket_article, :inbound_email, ticket: ticket)

        travel 10.minutes
      end

      # https://github.com/zammad/zammad/issues/3140
      it 'agent response clears #update_escalation_at' do
        expect { create(:ticket_article, :outbound_email, ticket: ticket) }
          .to change { ticket.reload.update_escalation_at }.to(nil)
      end

      # https://github.com/zammad/zammad/issues/3140
      it 'repeated customer requests do not #update_escalation_at' do
        expect { create(:ticket_article, :inbound_email, ticket: ticket) }
          .not_to change { ticket.reload.update_escalation_at }
      end
    end
  end

  describe '#escalation_first_response' do
    let(:force) { true } # initial calculation

    it 'returns attribute' do
      sla_247
      allow(instance_with_history).to receive(:escalation_disabled?).and_return(false)
      result = instance_with_history.send(:escalation_first_response)
      expect(result).to include first_response_escalation_at: 60.minutes.ago
    end

    it 'returns nil when no sla#first_response_time' do
      sla_247.update! first_response_time: nil
      allow(instance_with_history).to receive(:escalation_disabled?).and_return(false)
      result = instance_with_history.send(:escalation_first_response)
      expect(result).to include(first_response_escalation_at: nil)
    end
  end

  describe '#escalation_update' do
    it 'returns attribute' do
      sla_247
      ticket_with_history.last_contact_customer_at = 2.hours.ago
      allow(instance_with_history).to receive(:escalation_disabled?).and_return(false)
      result = instance_with_history.send(:escalation_update)
      expect(result).to include update_escalation_at: 60.minutes.ago
    end

    it 'returns nil when no sla#update_time' do
      sla_247.update! update_time: nil
      allow(instance_with_history).to receive(:escalation_disabled?).and_return(false)
      result = instance_with_history.send(:escalation_update)
      expect(result).to include(update_escalation_at: nil)
    end
  end

  describe '#escalation_close' do
    it 'returns attribute' do
      sla_247
      ticket_with_history.update! state: Ticket::State.lookup(name: 'open'), close_at: nil
      allow(instance_with_history).to receive(:escalation_disabled?).and_return(false)
      result = instance_with_history.send(:escalation_close)
      expect(result).to include close_escalation_at: 45.minutes.ago
    end

    it 'returns nil when no sla#solution_time' do
      sla_247.update! solution_time: nil
      allow(instance_with_history).to receive(:escalation_disabled?).and_return(false)
      result = instance_with_history.send(:escalation_close)
      expect(result).to include(close_escalation_at: nil)
    end
  end

  describe '#calculate_time' do
    before do
      sla_247
      start
    end

    let(:start) { 75.minutes.from_now.change(sec: 0) }

    it 'calculates target time that is given working minutes after start time' do
      expect(instance_with_history.send(:calculate_time, start, 30)).to eq(start + 1.hour)
    end

    it 'returns nil when given 0 span' do
      expect(instance_with_history.send(:calculate_time, start, 0)).to be_nil
    end

    it 'returns nil when given no span' do
      expect(instance_with_history.send(:calculate_time, start, nil)).to be_nil
    end
  end

  describe '#calculate_next_escalation' do
    it 'nil when escalation is disabled' do
      ticket.update! state: Ticket::State.lookup(name: 'closed')
      expect(instance.send(:calculate_next_escalation)).to be_nil
    end

    it 'first_response_escalation_at when earliest' do
      ticket.update! first_response_escalation_at: 1.hour.from_now, update_escalation_at: 2.hours.from_now, close_escalation_at: 3.hours.from_now
      expect(instance.send(:calculate_next_escalation)).to eq ticket.first_response_escalation_at
    end

    it 'update_escalation_at when earliest' do
      ticket.update! first_response_escalation_at: 2.hours.from_now, update_escalation_at: 1.hour.from_now, close_escalation_at: 3.hours.from_now
      expect(instance.send(:calculate_next_escalation)).to eq ticket.update_escalation_at
    end

    it 'close_escalation_at when earliest' do
      ticket.update! first_response_escalation_at: 2.hours.from_now, update_escalation_at: 1.hour.from_now, close_escalation_at: 30.minutes.from_now
      expect(instance.send(:calculate_next_escalation)).to eq ticket.close_escalation_at
    end

    it 'works when one of escalation times is not present' do
      ticket.update! first_response_escalation_at: 1.hour.from_now, update_escalation_at: nil, close_escalation_at: nil
      expect { instance.send(:calculate_next_escalation) }.not_to raise_error
    end
  end

  describe '#statistics_first_response' do
    it 'calculates statistics' do
      sla_247
      ticket_with_history.first_response_at = 45.minutes.ago
      instance_with_history.force!

      result = instance_with_history.send(:statistics_first_response)
      expect(result).to include(first_response_in_min: 75, first_response_diff_in_min: -15)
    end

    it 'does not touch statistics when sla time is nil' do
      sla_247.update! first_response_time: nil
      ticket_with_history.first_response_at = 45.minutes.ago
      instance_with_history.force!

      result = instance_with_history.send(:statistics_first_response)
      expect(result).to be_nil
    end
  end

  describe '#statistics_update' do
    before do
      sla_247
      freeze_time
    end

    it 'calculates statistics' do
      ticket_with_history.last_contact_customer_at = 61.minutes.ago
      ticket_with_history.last_contact_agent_at    = 60.minutes.ago

      result = instance_with_history.send(:statistics_update)
      expect(result).to include(update_in_min: 1, update_diff_in_min: 59)
    end

    it 'does not calculate statistics when customer respose is last' do
      ticket_with_history.last_contact_customer_at = 59.minutes.ago
      ticket_with_history.last_contact_agent_at    = 60.minutes.ago

      result = instance_with_history.send(:statistics_update)
      expect(result).to be_nil
    end

    it 'does not calculate statistics when only customer enquiry present' do
      create(:ticket_article, :inbound_email, ticket: ticket)

      result = instance.send(:statistics_update)
      expect(result).to be_nil
    end

    it 'calculates update statistics of last exchange' do
      create(:ticket_article, :inbound_email, ticket: ticket)
      travel 10.minutes
      create(:ticket_article, :outbound_email, ticket: ticket)

      instance.force!
      expect(instance.send(:statistics_update)).to include(update_in_min: 10, update_diff_in_min: 50)
    end

    context 'with multiple exchanges and later one being quicker' do
      before do
        create(:ticket_article, :inbound_email, ticket: ticket)
        travel 10.minutes
        create(:ticket_article, :outbound_email, ticket: ticket)
        travel 10.minutes
        create(:ticket_article, :inbound_email, ticket: ticket)
        travel 5.minutes
        create(:ticket_article, :outbound_email, ticket: ticket)
      end

      it 'keeps statistics of longest exchange' do
        expect(ticket.reload).to have_attributes(update_in_min: 10, update_diff_in_min: 50)
      end
    end

    it 'does not touch statistics when sla time is nil' do
      sla_247.update! update_time: nil
      ticket_with_history.last_contact_customer_at = 60.minutes.ago
      instance_with_history.force!

      result = instance_with_history.send(:statistics_update)
      expect(result).to be_nil
    end

    it 'does not touch statistics when last update is nil' do
      ticket_with_history.assign_attributes last_contact_agent_at: nil, last_contact_customer_at: nil
      instance_with_history.force!

      result = instance_with_history.send(:statistics_update)
      expect(result).to be_nil
    end
  end

  describe '#statistics_close' do
    it 'calculates statistics' do
      sla_247
      ticket_with_history.close_at = 50.minutes.ago
      instance_with_history.force!

      result = instance_with_history.send(:statistics_close)
      expect(result).to include(close_in_min: 70, close_diff_in_min: 5)
    end

    it 'does not touch statistics when sla time is nil' do
      sla_247.update! solution_time: nil
      ticket_with_history.close_at = 50.minutes.ago
      instance_with_history.force!

      result = instance_with_history.send(:statistics_close)
      expect(result).to be_nil
    end
  end

  describe '#calculate_minutes' do
    it 'calculates working minutes up to given time' do
      sla_247
      expect(instance_with_history.send(:calculate_minutes, ticket_with_history.created_at, 90.minutes.ago)).to be 30
    end

    it 'returns nil when given nil' do
      sla_247
      expect(instance.send(:calculate_minutes, ticket.created_at, nil)).to be_nil
    end
  end

  it 'switching state pushes escalation date' do
    sla_247
    open_ticket_with_history.reload
    expect(open_ticket_with_history.update_escalation_at).to eq open_ticket_with_history.created_at + 70.minutes
  end

  def without_update_escalation_information_callback(&block)
    Ticket.without_callback(:commit, :after, :update_escalation_information, &block)
  end
end

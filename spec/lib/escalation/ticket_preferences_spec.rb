# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Escalation::TicketPreferences do
  let(:instance) { described_class.new ticket }
  let(:ticket)   { create(:ticket) }

  describe '#sla_changed?' do
    it 'false when using same sla' do
      sla = create(:sla)
      instance.hash[:sla_id] = sla.id
      instance.hash[:sla_updated_at] = sla.updated_at

      expect(instance).not_to be_sla_changed(sla)
    end

    it 'true when using another sla' do
      sla  = create(:sla)
      sla2 = create(:sla)

      instance.hash[:sla_id] = sla.id
      instance.hash[:sla_updated_at] = sla.updated_at

      expect(instance).to be_sla_changed(sla2)
    end

    it 'true when using updated sla' do
      sla = create(:sla)

      instance.hash[:sla_id] = sla.id
      instance.hash[:sla_updated_at] = sla.updated_at

      sla.touch

      expect(instance).to be_sla_changed(sla)
    end

    it 'doe not fail given nil' do
      expect { instance.sla_changed?(nil) }.not_to raise_error
    end
  end

  describe '#calendar_changed?' do
    it 'false when using same calendar' do
      calendar = create(:calendar)
      instance.hash[:calendar_id] = calendar.id
      instance.hash[:calendar_updated_at] = calendar.updated_at

      expect(instance).not_to be_calendar_changed(calendar)
    end

    it 'true when using another calendar' do
      calendar  = create(:calendar)
      calendar2 = create(:calendar)

      instance.hash[:calendar_id] = calendar.id
      instance.hash[:calendar_updated_at] = calendar.updated_at

      expect(instance).to be_calendar_changed(calendar2)
    end

    it 'true when using updated calendar' do
      calendar = create(:calendar)

      instance.hash[:calendar_id] = calendar.id
      instance.hash[:calendar_updated_at] = calendar.updated_at

      calendar.touch

      expect(instance).to be_calendar_changed(calendar)
    end

    it 'doe not fail given nil' do
      expect { instance.calendar_changed?(nil) }.not_to raise_error
    end
  end

  describe '#first_response_at_changed?' do
    before { freeze_time }

    it 'true when changed' do
      instance.hash[:first_response_at] = 1.day.ago
      ticket.update! first_response_at: 1.week.ago

      expect(instance).to be_first_response_at_changed(ticket)
    end

    it 'false when matching' do
      instance.hash[:first_response_at] = 7.days.ago
      ticket.update! first_response_at: 1.week.ago

      expect(instance).not_to be_first_response_at_changed(ticket)
    end
  end

  describe '#last_update_at_changed?' do
    before { freeze_time }

    it 'true when changed' do
      instance.hash[:last_update_at] = 1.day.ago
      ticket.update! last_contact_customer_at: 1.week.ago

      expect(instance).to be_last_update_at_changed(ticket)
    end

    it 'false when matching' do
      instance.hash[:last_update_at] = 7.days.ago
      ticket.update! last_contact_customer_at: 1.week.ago

      expect(instance).not_to be_last_update_at_changed(ticket)
    end
  end

  describe '#close_at_changed?' do
    before { freeze_time }

    it 'true when changed' do
      instance.hash[:close_at] = 1.day.ago
      ticket.update! close_at: 1.week.ago

      expect(instance).to be_close_at_changed(ticket)
    end

    it 'false when matching' do
      instance.hash[:close_at] = 7.days.ago
      ticket.update! close_at: 1.week.ago

      expect(instance).not_to be_close_at_changed(ticket)
    end
  end

  describe '#property_changes?' do
    before { freeze_time }

    it 'false when no changes' do
      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).not_to be_property_changes(ticket)
    end

    it 'true when #first_response_at changes' do
      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 4.days.ago, close_at: 1.day.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).to be_property_changes(ticket)
    end

    it 'true when last_update_at changes' do
      ticket.update!       last_contact_customer_at: 2.weeks.ago, first_response_at: 5.days.ago, close_at: 1.day.ago
      instance.hash.merge! last_update_at:           1.week.ago,  first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).to be_property_changes(ticket)
    end

    it 'true when #close_at changes' do
      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 5.days.ago, close_at: 2.days.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).to be_property_changes(ticket)
    end
  end

  describe '#any_changes?' do
    let(:sla) { create(:sla) }

    before do
      freeze_time
      sla

      instance.hash[:sla_id] = sla.id
      instance.hash[:sla_updated_at] = sla.updated_at
      instance.hash[:calendar_id] = sla.calendar.id
      instance.hash[:calendar_updated_at] = sla.calendar.updated_at
    end

    it 'false when no changes' do
      instance.hash[:escalation_disabled] = false

      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).not_to be_any_changes(ticket, sla, false)
    end

    it 'true when time property changed' do
      instance.hash[:escalation_disabled] = false

      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 5.days.ago, close_at: 2.days.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).to be_any_changes(ticket, sla, false)
    end

    it 'true when sla changes' do
      sla2 = create(:sla)

      instance.hash[:escalation_disabled] = false

      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).to be_any_changes(ticket, sla2, false)
    end

    it 'true when escalability status changes' do
      instance.hash[:escalation_disabled] = true

      ticket.update!       last_contact_customer_at: 1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago
      instance.hash.merge! last_update_at:           1.week.ago, first_response_at: 5.days.ago, close_at: 1.day.ago

      expect(instance).to be_any_changes(ticket, sla, false)
    end
  end

  describe '#update_preferences' do
    it 'sets escalation_calculation in ticket preferences' do
      response = :spec
      allow(instance).to receive(:hash_of).and_return(response)
      instance.update_preferences(ticket, nil, false)
      expect(ticket.preferences[:escalation_calculation]).to eq response
    end
  end

  describe '#hash_of' do
    let(:last_contact)        { 6.days.ago }
    let(:first_response_at)   { 1.week.ago }
    let(:close_at)            { 1.day.ago }
    let(:sla)                 { create(:sla, updated_at: 1.week.from_now) }
    let(:escalation_disabled) { false }
    let(:result)              { instance.hash_of(ticket, sla, escalation_disabled) }

    before do
      freeze_time
      sla
      ticket.update! last_contact_customer_at: last_contact, first_response_at: first_response_at, close_at: close_at
    end

    it { expect(result).to be_a(Hash) }
    it { expect(result[:first_response_at]).to eq ticket.first_response_at }
    it { expect(result[:last_update_at]).to eq last_contact }
    it { expect(result[:close_at]).to eq ticket.close_at }
    it { expect(result[:sla_id]).to eq sla.id }
    it { expect(result[:sla_updated_at]).to eq sla.updated_at }
    it { expect(result[:calendar_id]).to eq sla.calendar.id }
    it { expect(result[:calendar_updated_at]).to eq sla.calendar.updated_at }
    it { expect(result[:escalation_disabled]).to eq escalation_disabled }

    context 'when sla not given' do
      let(:sla) { nil }

      it 'sla and calendar meta data are not included' do
        expect(result.keys).to eq %i[first_response_at last_update_at close_at escalation_disabled]
      end
    end
  end
end

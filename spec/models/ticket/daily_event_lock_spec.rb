# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::DailyEventLock, type: :model do
  subject(:ticket_daily_event_lock) { create(:ticket_daily_event_lock) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:lock_type) }
  it { is_expected.to validate_inclusion_of(:lock_type).in_array(%w[notification trigger]) }
  it { is_expected.to validate_presence_of(:lock_activator) }
  it { is_expected.to validate_inclusion_of(:lock_activator).in_array(%w[reminder_reached escalation escalation_warning]) }
  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_uniqueness_of(:date).scoped_to(:lock_type, :lock_activator, :ticket_id, :related_object_type, :related_object_id) }
  it { is_expected.to belong_to(:ticket) }
  it { is_expected.to belong_to(:related_object).optional }

  describe '.lock!' do
    it 'creates a daily lock successfully' do
      expect do
        described_class.lock!(lock_type: 'trigger', lock_activator: 'escalation', ticket: create(:ticket), related_object: create(:trigger))
      end.to change(described_class, :count).by(1)
    end

    it 'returns true if no lock exists for the same context' do
      expect(described_class.lock!(lock_type: 'trigger', lock_activator: 'escalation', ticket: create(:ticket), related_object: create(:trigger)))
        .to be true
    end

    it 'returns true if a lock is created for a different context' do
      described_class.lock!(lock_type: 'trigger', lock_activator: 'escalation', ticket: create(:ticket), related_object: create(:trigger))

      expect(described_class.lock!(lock_type: 'trigger', lock_activator: 'escalation', ticket: create(:ticket), related_object: create(:trigger)))
        .to be true
    end

    it 'returns false if a lock already exists for the same context' do
      ticket = create(:ticket)

      described_class.lock!(lock_type: 'trigger', lock_activator: 'escalation', ticket: ticket, related_object: create(:trigger))

      expect(described_class.lock!(lock_type: 'trigger', lock_activator: 'escalation', ticket: ticket, related_object: create(:trigger)))
        .to be true
    end

    it 'raises an error if given lock does not pass other validations' do
      expect do
        described_class.lock!(lock_type: 'invalid_type', lock_activator: 'escalation', ticket: create(:ticket), related_object: create(:trigger))
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '.cleanup' do
    let(:lock1) { create(:ticket_daily_event_lock) }
    let(:lock2) { create(:ticket_daily_event_lock) }

    it 'removes locks older than one week' do
      lock1
      travel 4.days
      lock2
      travel 4.days

      expect { described_class.cleanup }.to change(described_class, :all).to [lock2]
    end
  end
end

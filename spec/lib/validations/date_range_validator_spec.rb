# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::DateRangeValidator do

  let(:message) { 'must have a year between 1 and 9999' }

  context 'with a datetime column' do
    let(:ticket) { create(:ticket) }

    it 'accepts a four digit year' do
      ticket.close_at = Time.zone.local(2026, 8, 16, 10, 30)

      expect(ticket).to be_valid
    end

    it 'rejects a five digit year', :aggregate_failures do
      ticket.close_at = Time.zone.local(20_026, 8, 16, 10, 30)

      expect(ticket).not_to be_valid
      expect(ticket.errors[:close_at]).to include(message)
    end

    it 'rejects a five digit year given as string', :aggregate_failures do
      ticket.close_at = '20026-08-18T10:00:00Z'

      expect(ticket).not_to be_valid
      expect(ticket.errors[:close_at]).to include(message)
    end

    it 'rejects a negative year', :aggregate_failures do
      ticket.close_at = Time.zone.local(-1, 8, 16, 10, 30)

      expect(ticket).not_to be_valid
      expect(ticket.errors[:close_at]).to include(message)
    end

    it 'does not block updates of unrelated attributes on records with existing out of range values' do
      ticket.update_columns(close_at: Time.zone.local(20_026, 8, 16, 10, 30))
      ticket.reload

      expect { ticket.update!(note: 'unrelated change') }.not_to raise_error
    end
  end

  context 'with a custom object manager date attribute', db_strategy: :reset do
    it 'rejects a five digit year given as string', :aggregate_failures do
      create(:object_manager_attribute_date, name: 'test_date')
      ObjectManager::Attribute.migration_execute

      ticket = create(:ticket)
      ticket.test_date = '20026-08-18'

      expect(ticket).not_to be_valid
      expect(ticket.errors[:test_date]).to include(message)
    end
  end

  context 'with a date column' do
    let(:user) { create(:user) }

    it 'accepts a four digit year' do
      user.out_of_office_start_at = Date.new(2026, 8, 16)

      expect(user).to be_valid
    end

    it 'rejects a five digit year', :aggregate_failures do
      user.out_of_office_start_at = Date.new(20_026, 8, 16)

      expect(user).not_to be_valid
      expect(user.errors[:out_of_office_start_at]).to include(message)
    end
  end
end

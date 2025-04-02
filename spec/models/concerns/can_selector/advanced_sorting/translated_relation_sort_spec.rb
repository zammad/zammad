# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting::TranslatedRelationSort do
  describe '.applicable?' do
    it 'returns false if non relation field is given' do
      expect(described_class).not_to be_applicable({ column: 'number' }, 'de-de', Ticket)
    end

    it 'returns false if non translatable relation is given' do
      expect(described_class).not_to be_applicable({ column: 'group_id' }, 'de-de', Ticket)
    end

    it 'returns true if translatable relation foreign key is given' do
      expect(described_class).to be_applicable({ column: 'priority_id' }, 'de-de', Ticket)
    end

    it 'returns true if translatable relation name is given' do
      expect(described_class).to be_applicable({ column: 'priority' }, 'de-de', Ticket)
    end

    it 'returns false if translatable relation is given, but no locale is passed' do
      expect(described_class).not_to be_applicable({ column: 'priority' }, nil, Ticket)
    end
  end

  describe '#calculate_sorting' do
    let(:input)    { { column: 'state', direction: 'ASC' } }
    let(:instance) { described_class.new(input, locale, Ticket) }
    let(:result)   { instance.calculate_sorting }

    if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
      let(:column_reference) { '`tickets`.`state_id`' }
      let(:order_reference)  { '`_advanced_sorting_Ticket_state` ASC' }
    else
      let(:column_reference) { '"tickets"."state_id"' }
      let(:order_reference)  { '"_advanced_sorting_Ticket_state" ASC' }
    end

    context 'when locale is de-de' do
      let(:locale) { 'de-de' }

      it 'returns string with foreign key and IDs' do
        expect(result).to include(
          select: include(column_reference).and(include('4,1,2,3,6,5')),
          order:  order_reference,
        )
      end
    end

    context 'when locale is en-us' do
      let(:locale) { 'en-us' }

      it 'returns string with foreign key and IDs' do
        expect(result).to include(
          select: include(column_reference).and(include('4,5,1,2,6,3')),
          order:  order_reference,
        )
      end
    end
  end
end

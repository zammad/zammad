# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting::UntranslatedRelationSort do
  describe '.applicable?' do
    it 'returns false if non relation field is given' do
      expect(described_class).not_to be_applicable({ column: 'number' }, 'de-de', Ticket)
    end

    it 'returns false if translatable relation is given' do
      expect(described_class).not_to be_applicable({ column: 'priority_id' }, 'de-de', Ticket)
    end

    it 'returns true if non-translatable relation foreign key is given' do
      expect(described_class).to be_applicable({ column: 'group_id' }, 'de-de', Ticket)
    end

    it 'returns true if non-translatable relation name is given' do
      expect(described_class).to be_applicable({ column: 'group' }, 'de-de', Ticket)
    end
  end

  describe '#calculate_sorting' do
    let(:input)    { { column:, direction: 'ASC' } }
    let(:instance) { described_class.new(input, 'de-de', Ticket) }
    let(:result)   { instance.calculate_sorting }

    context 'when relation is to users table' do
      let(:column) { 'customer_id' }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'returns complex MySQL statement' do
          expect(result).to include(
            order:  '`_advanced_sorting_tickets_customer_id` ASC',
            joins:  include('_advanced_sorting_table_tickets_customer_id'),
            group:  include('firstname').and(include('lastname')).and(include('email')),
            select: include('when character_length').and(include('as `_advanced_sorting_tickets_customer_id`'))
          )
        end
      else
        it 'returns complex SQL statement' do
          expect(result).to include(
            order:  '"_advanced_sorting_tickets_customer_id" ASC',
            joins:  include('_advanced_sorting_table_tickets_customer_id'),
            group:  include('firstname').and(include('lastname')).and(include('email')),
            select: include('when character_length').and(include('as "_advanced_sorting_tickets_customer_id"'))
          )
        end
      end

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'does not include collation on Mysql-like databases' do
          expect(result).not_to include(
            select: include('de-DE')
          )
        end
      else
        it 'includes collation on Postgres' do
          expect(result).to include(
            select: include('COLLATE "de-DE-x-icu"')
          )
        end
      end
    end

    context 'when relation is not to users table' do
      let(:column) { 'group_id' }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'returns Mysql SQL statement to join and sort by it' do
          expect(result).to include(
            joins: :group,
            group: '`groups`.`name`',
            order: '`groups`.`name`  ASC',
          )
        end
      else
        it 'returns SQL statement to join and sort by it' do
          expect(result).to include(
            joins: :group,
            group: '"groups"."name"',
            order: '"groups"."name" COLLATE "de-DE-x-icu" ASC',
          )
        end
      end
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting::DefaultSort do
  describe '.applicable?' do
    it 'returns true' do
      expect(described_class).to be_applicable('any input', 'any locale', 'any object')
    end
  end

  describe '#calculate_sorting' do
    let(:input)    { { column:, direction: 'ASC' } }
    let(:instance) { described_class.new(input, 'de-de', Ticket) }

    context 'when given a string column' do
      let(:column) { 'number' }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'does not include collation on Mysql-like databases' do
          expect(instance.calculate_sorting)
            .to eq('`tickets`.`number`  ASC')
        end
      else
        it 'includes collation on Postgres' do
          expect(instance.calculate_sorting)
            .to eq('"tickets"."number" COLLATE "de-DE-x-icu" ASC')
        end
      end
    end

    context 'when given a non-string column' do
      let(:column) { 'article_count' }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'does not include collation in MySQL' do
          expect(instance.calculate_sorting)
            .to eq('`tickets`.`article_count` ASC')
        end
      else
        it 'does not include collation' do
          expect(instance.calculate_sorting)
            .to eq('"tickets"."article_count" ASC')
        end
      end
    end

    context 'when a relation name is given' do
      let(:column) { 'group' }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'adds _id to match database column in Mysql' do
          expect(instance.calculate_sorting)
            .to eq('`tickets`.`group_id` ASC')
        end
      else
        it 'adds _id to match database column' do
          expect(instance.calculate_sorting)
            .to eq('"tickets"."group_id" ASC')
        end
      end
    end

    context 'when a non-existant column is given' do
      let(:column) { 'created_at' }

      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        it 'uses created_at as a fallback in Mysql' do
          expect(instance.calculate_sorting)
            .to eq('`tickets`.`created_at` ASC')
        end
      else
        it 'uses created_at as a fallback' do
          expect(instance.calculate_sorting)
            .to eq('"tickets"."created_at" ASC')
        end
      end
    end
  end
end

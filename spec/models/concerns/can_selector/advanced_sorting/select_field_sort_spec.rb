# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting::SelectFieldSort, db_strategy: :reset do
  let(:attribute_params) { attributes_for(:object_manager_attribute_select) }
  let(:translate)        { true }
  let(:custom_sort)      { false }

  let(:object_manager_attribute) do
    params = attribute_params
    params[:data_option][:translate] = translate
    params[:data_option][:options]   = {
      '1' => 'Role',
      '2' => 'User',
      '3' => 'Group',
    }

    if custom_sort
      params[:data_option][:customsort] = 'on'
      params[:data_option][:options] = [
        {
          'name'  => 'Group',
          'value' => '3',
        },
        {
          'name'  => 'Role',
          'value' => '1',
        },
        {
          'name'  => 'User',
          'value' => '2',
        },
      ]
    end

    attr = ObjectManager::Attribute.add(params)

    ObjectManager::Attribute.migration_execute(false)

    attr
  end

  describe '.applicable?' do
    context 'when attribute is not a select field' do
      let(:attribute_params) { attributes_for(:object_manager_attribute_text) }

      it 'returns false' do
        expect(described_class).not_to be_applicable({ column: object_manager_attribute.name }, 'de-de', Ticket)
      end
    end

    context 'when attribute is a select field' do
      it 'returns true' do
        expect(described_class).to be_applicable({ column: object_manager_attribute.name }, 'de-de', Ticket)
      end
    end
  end

  describe '#calculate_sorting' do
    let(:input)    { { column: object_manager_attribute.name, direction: 'ASC' } }
    let(:instance) { described_class.new(input, locale, Ticket) }
    let(:result)   { instance.calculate_sorting }

    if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
      let(:column_reference) { "`tickets`.`#{object_manager_attribute.name}`" }
      let(:order_reference)  { "`_advanced_sorting_Ticket_#{object_manager_attribute.name}` ASC" }
    else
      let(:column_reference) { "\"tickets\".\"#{object_manager_attribute.name}\"" }
      let(:order_reference)  { "\"_advanced_sorting_Ticket_#{object_manager_attribute.name}\" ASC" }
    end

    context 'when translate is true' do
      let(:translate) { true }

      context 'when locale is de-de' do
        let(:locale) { 'de-de' }

        it 'returns correct result' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include("'2','3','1'")),
          )
        end
      end

      context 'when locale is en-us' do
        let(:locale) { 'en-us' }

        it 'returns correct result' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include("'3','1','2'")),
          )
        end
      end
    end

    context 'when translate is false' do
      let(:translate) { false }

      context 'when locale is de-de' do
        let(:locale) { 'de-de' }

        it 'returns correct result' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include("'3','1','2'")),
          )
        end
      end

      context 'when locale is en-us' do
        let(:locale) { 'en-us' }

        it 'returns correct result' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include("'3','1','2'")),
          )
        end
      end
    end

    context 'when custom sort is set' do
      let(:custom_sort) { true }

      shared_examples 'correct result (custom sort)' do
        it 'returns correct result for custom sort' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include("'3','1','2'")),
          )
        end
      end

      context 'when translate is true' do
        let(:translate) { true }

        context 'when locale is de-de' do
          let(:locale) { 'de-de' }

          it_behaves_like 'correct result (custom sort)'
        end

        context 'when locale is en-us' do
          let(:locale) { 'en-us' }

          it_behaves_like 'correct result (custom sort)'
        end
      end

      context 'when translate is false' do
        let(:translate) { false }

        context 'when locale is de-de' do
          let(:locale) { 'de-de' }

          it_behaves_like 'correct result (custom sort)'
        end

        context 'when locale is en-us' do
          let(:locale) { 'en-us' }

          it_behaves_like 'correct result (custom sort)'
        end
      end
    end
  end
end

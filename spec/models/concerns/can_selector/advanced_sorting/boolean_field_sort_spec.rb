# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting::BooleanFieldSort, db_strategy: :reset do
  let(:attribute_params) { attributes_for(:object_manager_attribute_boolean) }
  let(:translate)        { true }

  let(:object_manager_attribute) do
    params = attribute_params
    params[:data_option][:translate] = translate
    params[:data_option][:options]   = {
      true  => 'Yes',
      false => 'No',
    }

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
            select: include(column_reference).and(include('true,false')),
          )
        end
      end

      context 'when locale is en-us' do
        let(:locale) { 'en-us' }

        it 'returns correct result' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include('false,true')),
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
            select: include(column_reference).and(include('false,true')),
          )
        end
      end

      context 'when locale is en-us' do
        let(:locale) { 'en-us' }

        it 'returns correct result' do
          expect(result).to include(
            order:  order_reference,
            select: include(column_reference).and(include('false,true')),
          )
        end
      end
    end
  end
end

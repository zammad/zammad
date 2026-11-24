# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    let(:column_reference) { "\"tickets\".\"#{object_manager_attribute.name}\"" }
    let(:order_reference)  { "\"_advanced_sorting_Ticket_#{object_manager_attribute.name}\" ASC" }

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

        context 'when a translation changes after the sorting was cached' do
          before do
            instance.calculate_sorting
            allow(Translation).to receive(:translate_all).and_call_original
          end

          it 'sorts by the changed translation of the locale' do
            Translation.find_by(locale: 'de-de', source: 'Role').update!(target: 'Aufgabe')

            expect(described_class.new(input, locale, Ticket).calculate_sorting).to include(
              select: include("'1','2','3'"),
            )
          end

          it 'keeps the cached sorting if a translation of another locale changes' do
            Translation.find_by(locale: 'en-us', source: 'Role').update!(target: 'Duty')
            described_class.new(input, locale, Ticket).calculate_sorting

            expect(Translation).not_to have_received(:translate_all)
          end
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

        context 'when the sorting was cached for another locale before' do
          before do
            described_class.new(input, 'de-de', Ticket).calculate_sorting
          end

          it 'returns the order of its own locale' do
            expect(result).to include(
              select: include(column_reference).and(include("'3','1','2'")),
            )
          end
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

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Translation::Search do
  describe '#execute' do
    let(:locale)                      { 'en-us' }
    let(:filter_locale)               { locale }
    let(:query)                       { nil }
    let(:translation_search_service)  { described_class.new(locale: filter_locale, query:) }

    context 'when query is nil', :aggregate_failures do
      it 'return default list' do
        expect(translation_search_service.execute[:items].count).to eq(150)
        expect(translation_search_service.execute[:total_count]).to be > 150
      end

      it 'includes already translated suggestions with translation item' do
        result = translation_search_service.execute
        priority_name = Ticket::Priority.first.name
        first_priority_translation = result[:items].select { |item| item[:source].eql?(priority_name) }

        expect(first_priority_translation.length).to be(1)
        expect(first_priority_translation[0][:id]).to eq(Translation.find_source(locale, priority_name).id)
      end
    end

    context 'with specific query' do
      let(:query) { SecureRandom.uuid }

      before do
        create(:translation, locale: locale, source: "Other #{query}", target: "Andere #{query}")
        create(:translation, locale: locale, source: "Example #{query}", target: "Ein #{query}", is_synchronized_from_codebase: true)
      end

      context 'with not matching locale' do
        let(:filter_locale) { 'de-de' }

        it 'returns no result' do
          expect(translation_search_service.execute[:items].count).to eq(0)
        end
      end

      context 'when case sensitive should match' do
        let(:query) { Translation.last.source.downcase }

        it 'returns also with case insensitive a result' do
          expect(translation_search_service.execute[:items].count).to eq(2)
        end
      end

      context 'with matching query' do
        shared_examples 'returns filtered result' do |factory_name, attribute, count|
          before do
            create(factory_name, attribute => "#{factory_name} #{query}")
          end

          it 'returns filtered result' do
            expect(translation_search_service.execute[:items].count).to eq(count)
          end
        end

        context 'with custom priority' do
          it_behaves_like 'returns filtered result', :ticket_priority, 'name', 2
        end

        context 'with custom state' do
          it_behaves_like 'returns filtered result', :ticket_state, 'name', 2
        end

        context 'with custom overview' do
          it_behaves_like 'returns filtered result', :overview, 'name', 2
        end

        context 'with custom macro' do
          it_behaves_like 'returns filtered result', :macro, 'name', 2
        end

        context 'with custom object attribute' do
          before do
            create(:object_manager_attribute_select, display: "Select #{query}", data_option_options: [{ name: query, value: query }])
          end

          it 'returns filtered result' do
            expect(translation_search_service.execute[:items].count).to eq(3)
          end

          context 'with not translatabale option' do
            before do
              create(:object_manager_attribute_select, display: "Select2 #{query}", data_option:   {
                       default:   '',
                       options:   [{ name: "item #{query}", value: "item #{query}" }],
                       translate: false
                     })
            end

            it 'returns filtered result' do
              expect(translation_search_service.execute[:items].count).to eq(4)
            end
          end
        end

        context 'with multiple suggestion with the same name' do
          before do
            create(:ticket_priority, name: "high #{query}")
            create(:object_manager_attribute_select, display: "high #{query}")
          end

          it 'returns filtered result without duplicate entries' do
            expect(translation_search_service.execute[:items].count).to eq(2)
          end
        end
      end
    end
  end
end

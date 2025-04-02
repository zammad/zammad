# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanSelector::AdvancedSorting::TreeSelectFieldSort, db_strategy: :reset do
  let(:attribute_params) { attributes_for(:object_manager_attribute_tree_select) }
  let(:translate)        { true }

  let(:object_manager_attribute) do
    params = attribute_params
    params[:data_option][:translate] = translate

    attr = ObjectManager::Attribute.add(attribute_params)

    ObjectManager::Attribute.migration_execute(false)

    attr
  end

  describe '.applicable?' do
    context 'when attribute is not a tree select field' do
      let(:attribute_params) { attributes_for(:object_manager_attribute_text) }

      it 'returns false' do
        expect(described_class).not_to be_applicable({ column: object_manager_attribute.name }, 'de-de', Ticket)
      end
    end

    context 'when attribute is a tree select field' do
      it 'returns true' do
        expect(described_class).to be_applicable({ column: object_manager_attribute.name }, 'de-de', Ticket)
      end

      context 'when translation is disabled' do
        let(:translate) { false }

        it 'returns false + raises an error', :aggregate_failures do
          expect(described_class).not_to be_applicable({ column: object_manager_attribute.name }, 'de-de', Ticket)

          expect { described_class.new({ column: object_manager_attribute.name }, 'de-de', Ticket) }.to raise_error(RuntimeError, include('can only be used with translatable fields'))
        end
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

    context 'when locale is de-de' do
      let(:locale) { 'de-de' }

      it 'returns correct result' do
        expect(result).to include(
          order:  order_reference,
          select: include(column_reference).and(include("'Change request','Service request','Service request::Consulting','Service request::New hardware','Service request::New software requirement','Incident','Incident::Hardware','Incident::Hardware::Keyboard','Incident::Hardware::Monitor','Incident::Hardware::Mouse','Incident::Softwareproblem','Incident::Softwareproblem::CRM','Incident::Softwareproblem::EDI','Incident::Softwareproblem::MS Office','Incident::Softwareproblem::MS Office::Excel','Incident::Softwareproblem::MS Office::Outlook','Incident::Softwareproblem::MS Office::PowerPoint','Incident::Softwareproblem::MS Office::Word','Incident::Softwareproblem::SAP','Incident::Softwareproblem::SAP::Authentication','Incident::Softwareproblem::SAP::Not reachable'")),
        )
      end
    end

    context 'when locale is en-us' do
      let(:locale) { 'en-us' }

      it 'returns correct result' do
        expect(result).to include(
          order:  order_reference,
          select: include(column_reference).and(include("'Change request','Incident','Incident::Hardware','Incident::Hardware::Keyboard','Incident::Hardware::Monitor','Incident::Hardware::Mouse','Incident::Softwareproblem','Incident::Softwareproblem::CRM','Incident::Softwareproblem::EDI','Incident::Softwareproblem::MS Office','Incident::Softwareproblem::MS Office::Excel','Incident::Softwareproblem::MS Office::Outlook','Incident::Softwareproblem::MS Office::PowerPoint','Incident::Softwareproblem::MS Office::Word','Incident::Softwareproblem::SAP','Incident::Softwareproblem::SAP::Authentication','Incident::Softwareproblem::SAP::Not reachable','Service request','Service request::Consulting','Service request::New hardware','Service request::New software requirement'")),
        )
      end
    end
  end
end

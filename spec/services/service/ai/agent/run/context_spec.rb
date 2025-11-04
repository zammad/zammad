# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context, type: :service do
  let(:ticket) { create(:ticket, title: 'Test Ticket', group: group) }
  let(:group)  { create(:group, name: 'Example Group') }
  let(:object_attributes_context) do
    {
      'group_id'    => { group.id.to_s => 'Example group for testing purposes' },
      'priority_id' => {}, # this means all priorities
      'type'        => { 'Incident' => 'Incident type tickets' }
    }
  end
  let(:instruction_context) do
    {
      'object_attributes' => object_attributes_context
    }
  end
  let(:entity_context) do
    {
      'object_attributes' => %w[title group_id type]
    }
  end
  let(:context) { described_class.new(entity_object: ticket, instruction_context: instruction_context, entity_context: entity_context) }

  let(:expected_instruction_result) do
    {
      object_attributes: {
        'group_id'    => { items: [{
          value:       group.id,
          label:       'Example Group',
          description: 'Example group for testing purposes'
        }], label: 'Group' },
        'priority_id' => { items: Ticket::Priority.all.map do |priority|
          {
            value: priority.id,
            label: priority.name,
          }
        end, label: 'Priority' },
        'type'        => { items: [ { value: 'Incident', label: 'Incident', description: 'Incident type tickets' } ], label: 'Type' }
      }
    }
  end

  let(:expected_entity_result) do
    {
      object_attributes: {
        'title'    => {
          value: 'Test Ticket'
        },
        'group_id' => {
          value: group.id,
          label: 'Example Group'
        }
      }
    }
  end

  describe '#prepare_instructions' do
    context 'when object_attributes_context is blank' do
      let(:instruction_context) do
        {
          object_attributes: {}
        }
      end
      let(:expected_instruction_result) { {} }

      it 'returns empty hash' do
        expect(context.prepare_instructions).to eq(expected_instruction_result)
      end
    end

    context 'when object_attributes_context is present' do
      it 'returns prepared instruction context' do
        result = context.prepare_instructions

        expect(result[:object_attributes]).to eq(expected_instruction_result[:object_attributes])
      end
    end
  end

  describe '#prepare_entity' do
    context 'when entity_object_attributes is blank default is used' do
      let(:entity_context) do
        {
          object_attributes: []
        }
      end

      it 'returns empty hash' do
        result = context.prepare_entity
        expect(result[:object_attributes]).to eq({
                                                   'title' => {
                                                     value: 'Test Ticket'
                                                   }
                                                 })
      end
    end

    context 'when entity_object_attributes is present' do
      it 'returns entity object attributes with values and labels' do
        result = context.prepare_entity

        expect(result[:object_attributes]).to include(
          'title'    => {
            value: 'Test Ticket'
          },
          'group_id' => {
            value: group.id,
            label: 'Example Group'
          }
        )
      end
    end

    context 'when entity_object_attributes includes options field' do
      let(:entity_context) do
        {
          'object_attributes' => %w[type]
        }
      end

      it 'returns options with value and label' do
        ticket.update!(type: 'Incident')

        result = context.prepare_entity

        expect(result[:object_attributes]).to include(
          'type' => {
            value: 'Incident',
            label: 'Incident'
          }
        )
      end
    end

    context 'when articles are present' do
      let(:articles) { create_list(:ticket_article, 2, ticket: ticket) }
      let(:entity_context) do
        {
          'object_attributes' => %w[title],
          'articles'          => 'all'
        }
      end
      let(:mock_provider) { instance_spy(AI::Provider::OpenAI) }

      before do
        articles

        setup_ai_provider('open_ai')

        # Mock the AI provider to avoid real API calls
        allow(AI::Provider::OpenAI).to receive(:new).and_return(mock_provider)
        allow(mock_provider).to receive(:ask).and_return('processed article content')
      end

      it 'includes processed articles in the result' do
        result = context.prepare_entity

        expect(result[:articles].length).to eq(2)
      end
    end
  end
end

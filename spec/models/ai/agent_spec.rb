# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe AI::Agent, aggregate_failures: true, current_user_id: 1, type: :model do
  subject(:ai_agent) { create(:ai_agent, action_definition:) }

  let(:action_definition) { {} }

  it_behaves_like 'ApplicationModel'
  it_behaves_like 'HasXssSanitizedNote', model_factory: :trigger

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:note).is_at_most(250) }

    it 'validates agent_type inclusion' do
      expect(ai_agent).to validate_inclusion_of(:agent_type)
        .in_array(AI::Agent::Type.available_types.map { |t| t.name.demodulize }).allow_blank
    end
  end

  describe '#destroy' do
    context 'when no dependencies' do
      it 'removes the object' do
        expect { ai_agent.destroy }.to change(ai_agent, :destroyed?).to true
      end
    end

    context 'when related object exists' do
      let!(:trigger) { create(:trigger, perform: { 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id.to_s } }) }

      it 'raises error with details' do
        expect { ai_agent.destroy }
          .to raise_exception(
            be_an_instance_of(Exceptions::UnprocessableEntity)
            .and(have_attributes(
                   message: 'This object is referenced by other object(s) and thus cannot be deleted: %s',
                   entity:  eq(["Trigger / #{trigger.name} (##{trigger.id})"])
                 ))
          )
      end
    end
  end

  describe '#execution_definition' do
    context 'when agent_type is blank' do
      it 'returns the original definition' do
        expect(ai_agent.execution_definition).to eq(ai_agent.definition)
      end
    end

    context 'when agent_type is present' do
      let(:ai_agent)        { create(:ai_agent, agent_type: 'TicketGroupDispatcher') }
      let(:type_instance)   { AI::Agent::Type::TicketGroupDispatcher.new }
      let(:type_definition) { type_instance.definition.deep_stringify_keys }

      it 'merges type definition with database definition' do
        result = ai_agent.execution_definition

        expect(result['role_description']).to eq(type_definition['role_description'])
        expect(result['instruction']).to eq(type_definition['instruction'])
        expect(result['result_structure']).to eq(type_definition['result_structure'])
      end

      it 'allows database values to override type defaults' do
        custom_role = 'Custom role description'
        ai_agent.update!(definition: { 'role_description' => custom_role })

        result = ai_agent.execution_definition
        expect(result['role_description']).to eq(custom_role)
        expect(result['instruction']).to eq(type_definition['instruction'])
      end
    end
  end

  describe '#execution_action_definition' do
    context 'when agent_type is blank' do
      it 'returns the original action_definition' do
        expect(ai_agent.execution_action_definition).to eq(ai_agent.action_definition)
      end
    end

    context 'when agent_type is present' do
      let(:ai_agent) { create(:ai_agent, agent_type: 'TicketGroupDispatcher') }
      let(:type_instance)          { AI::Agent::Type::TicketGroupDispatcher.new }
      let(:type_action_definition) { type_instance.action_definition.deep_stringify_keys }

      it 'merges type action definition with database action definition' do
        result = ai_agent.execution_action_definition

        expect(result).to eq(type_action_definition)
      end

      it 'allows database values to override type defaults' do
        custom_mapping = { 'mapping' => { 'ticket.state_id' => { 'value' => 'closed' } } }
        ai_agent.update!(action_definition: custom_mapping)

        result = ai_agent.execution_action_definition

        # Should include both the type defaults and custom values
        expect(result['mapping']).to include(type_action_definition['mapping'])
        expect(result['mapping']).to include(custom_mapping['mapping'])
      end
    end
  end

  describe '#assets' do
    context 'with referencing job and trigger' do
      let(:trigger) do
        create(:trigger,
               perform: {
                 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id }
               })
      end
      let(:job) do
        create(:job,
               perform: {
                 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id }
               })
      end

      before { trigger && job }

      it 'includes references to referenced objects' do
        assets = ai_agent.assets.dig(:AIAgent, ai_agent.id)

        expect(assets).to include(
          'references' => include(
            'Job'     => contain_exactly(include('id' => job.id, 'name' => job.name)),
            'Trigger' => contain_exactly(include('id' => trigger.id, 'name' => trigger.name)),
          )
        )
      end

      it 'includes assets of referenced objects' do
        assets = ai_agent.assets

        expect(assets).to include_assets_of(job, trigger)
      end
    end

    context 'without referencing job and trigger' do
      it 'returns empty references' do
        assets = ai_agent.assets.dig(:AIAgent, ai_agent.id)

        expect(assets).to include('references' => be_empty)
      end
    end
  end
end

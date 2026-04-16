# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

        expect(result).to include(type_action_definition)
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

  describe '.working_on_ticket' do
    let(:ticket) { create(:ticket) }
    let(:article)        { create(:ticket_article, ticket: ticket) }
    let(:ai_agent)       { create(:ai_agent) }
    let(:other_ticket)   { create(:ticket) }
    let(:other_article)  { create(:ticket_article, ticket: other_ticket) }
    let(:other_ai_agent) { create(:ai_agent) }

    def make_job(agent, ticket, article)
      TriggerAIAgentJob.perform_later(
        agent,
        ticket,
        article,
        changes:        nil,
        user_id:        nil,
        execution_type: nil,
        event_type:     nil,
      )
    end

    context 'when no agents are enqueued' do
      it 'returns false' do
        expect(described_class).not_to be_working_on_ticket(ticket)
      end
    end

    context 'when an agent on the ticket is enqueued' do
      it 'returns true' do
        make_job(ai_agent, ticket, article)

        expect(described_class).to be_working_on_ticket(ticket)
      end
    end

    context 'when an agent on another ticket is enqueued' do
      it 'returns false' do
        make_job(ai_agent, other_ticket, other_article)

        expect(described_class).not_to be_working_on_ticket(ticket)
      end
    end

    context 'when multiple agents on the same ticket are enqueued' do
      it 'returns true' do
        make_job(ai_agent, ticket, article)
        make_job(other_ai_agent, ticket, article)

        expect(described_class).to be_working_on_ticket(ticket)
      end
    end

    context 'when same agent on multiple tickets is enqueued' do
      it 'returns true' do
        make_job(ai_agent, ticket, article)
        make_job(ai_agent, other_ticket, other_article)

        expect(described_class).to be_working_on_ticket(ticket)
      end
    end
  end

  describe '.cleanup_orphan_jobs' do
    let(:ticket) { create(:ticket, ai_agent_running:) }

    before do
      allow(described_class).to receive(:working_on_ticket?).with(ticket).and_return(job_enqueued)
      allow(Rails.cache).to receive(:delete)
    end

    context 'when a ticket ai_agent_running flag is true but no jobs are enqueued' do
      let(:ai_agent_running) { true }
      let(:job_enqueued)     { false }

      it 'resets the ai_agent_running flag' do
        expect { described_class.cleanup_orphan_jobs }
          .to change { ticket.reload.ai_agent_running }
          .to false
      end

      it 'clears the ticket cache' do
        described_class.cleanup_orphan_jobs

        expect(Rails.cache).to have_received(:delete).with("Ticket::aws::#{ticket.id}")
      end
    end

    context 'when a ticket ai_agent_running flag is true and a job is enqueued' do
      let(:ai_agent_running) { true }
      let(:job_enqueued)     { true }

      it 'does not touch the ticket' do
        expect { described_class.cleanup_orphan_jobs }
          .not_to change { ticket.reload.ai_agent_running }
      end

      it 'does not clear the ticket cache' do
        described_class.cleanup_orphan_jobs

        expect(Rails.cache).not_to have_received(:delete)
      end
    end

    context 'when a ticket ai_agent_running flag is false but a job is enqueued' do
      let(:ai_agent_running) { false }
      let(:job_enqueued)     { true }

      it 'does not touch the ticket' do
        expect { described_class.cleanup_orphan_jobs }
          .not_to change { ticket.reload.ai_agent_running }
      end

      it 'does not clear the ticket cache' do
        described_class.cleanup_orphan_jobs

        expect(Rails.cache).not_to have_received(:delete)
      end
    end
  end
end

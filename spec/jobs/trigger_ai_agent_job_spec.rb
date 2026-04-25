# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TriggerAIAgentJob, type: :job do
  subject(:ai_agent) { create(:ai_agent) }

  let(:ticket)   { create(:ticket) }
  let(:article)  { create(:ticket_article, ticket:) }

  let(:perform) do
    described_class.perform_now(
      ai_agent,
      ticket,
      article,
      changes:        nil,
      user_id:        nil,
      execution_type: nil,
      event_type:     nil,
    )
  end

  let(:job) do
    described_class.perform_later(
      ai_agent,
      ticket,
      article,
      changes:        nil,
      user_id:        nil,
      execution_type: nil,
      event_type:     nil,
    )
  end

  context 'when serialized model argument gets deleted' do
    shared_examples 'handle deleted argument models' do
      it 'raises no error' do
        expect { ActiveJob::Base.execute job.serialize }.not_to raise_error
      end

      it "doesn't perform request" do
        allow(Service::AI::Agent::Run).to receive(:execute)
        ActiveJob::Base.execute serialized_job
        expect(Service::AI::Agent::Run).not_to have_received(:execute)
      end
    end

    let(:serialized_job) { job.serialize }

    context 'when AI Agent gets deleted' do
      before { serialized_job && ai_agent.destroy! }

      include_examples 'handle deleted argument models'
    end

    context 'when Ticket gets deleted' do
      before { serialized_job && article.destroy! && ticket.destroy! }

      include_examples 'handle deleted argument models'
    end

    context 'when Article gets deleted' do
      before { serialized_job && article.destroy! }

      include_examples 'handle deleted argument models'
    end
  end

  describe '#perform' do
    before do
      allow(Service::AI::Agent::Run).to receive(:execute).and_call_original
    end

    it 'executes the AI Agent service', aggregate_failures: true do
      perform

      expect(Service::AI::Agent::Run).to have_received(:execute).with(ai_agent:, ticket:, article:)
    end
  end

  describe 'agents-in-progress tracker' do
    context 'when AI agent is already in the list' do
      # https://github.com/zammad/zammad/issues/5908
      it 'enqueues another job to check ai_agent_running flag afterards' do
        ticket.update! ai_agent_running: true

        expect { ActiveJob::Base.execute job.serialize }
          .to have_enqueued_job(AIAgentMarkAsGone).with(ticket)
      end

      # https://github.com/zammad/zammad/issues/5908
      it 'sets ticket ai_agent_running flag to false when job is retried enough times' do
        job

        allow_any_instance_of(described_class).to receive(:perform).and_raise(Service::AI::Agent::Run::TemporaryError)

        expect do
          4.times { ActiveJob::Base.execute job.serialize }

          ActiveJob::Base.execute job.serialize
        end
          .to have_enqueued_job(AIAgentMarkAsGone).with(ticket).once
      end
    end
  end
end

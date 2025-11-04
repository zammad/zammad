# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
        expect_any_instance_of(Service::AI::Agent::Run).not_to receive(:execute)
        ActiveJob::Base.execute serialized_job
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
      allow(Service::AI::Agent::Run).to receive(:new).and_call_original
      allow_any_instance_of(Service::AI::Agent::Run).to receive(:execute)
    end

    it 'executes the AI Agent service', aggregate_failures: true do
      expect_any_instance_of(Service::AI::Agent::Run).to receive(:execute)

      perform

      expect(Service::AI::Agent::Run).to have_received(:new).with(ai_agent:, ticket:, article:)
    end
  end

  describe 'agents-in-progress tracker' do
    context 'when adding AI Agent to the list' do
      context 'with a job added' do
        before { job }

        it 'marks as AI Agent working on the ticket' do
          expect(described_class).to be_working_on(ticket)
        end

        it 'marks as AI Agent not working on the ticket, if asked to exclude the job' do
          expect(described_class).not_to be_working_on(ticket, exclude: job)
        end
      end
    end

    context 'when AI agent is already in the list' do
      before { job }

      it 'removes AI agent from the list when job is done' do
        allow_any_instance_of(described_class).to receive(:perform)

        expect { ActiveJob::Base.execute job.serialize }
          .to change { described_class.working_on?(ticket) }
          .to false
      end

      it 'sets ticket ai_agent_running flag to false when job is done' do
        ticket.update! ai_agent_running: true

        expect { ActiveJob::Base.execute job.serialize }
          .to change { ticket.reload.ai_agent_running }
          .to false
      end

      it 'checks lock without given job' do
        allow(described_class).to receive(:working_on).and_call_original

        ActiveJob::Base.execute job.serialize

        expect(described_class).to have_received(:working_on)
          .with(ticket, exclude: have_attributes(job_id: job.job_id))
      end

      it 'removes AI agent from the list when job throws an error' do
        allow_any_instance_of(described_class).to receive(:perform).and_raise(Service::AI::Agent::Run::PermanentError)

        expect { ActiveJob::Base.execute job.serialize }
          .to change { described_class.working_on?(ticket) }
          .to false
      end

      it 'does not remove AI agent from the list when job is retried' do
        allow_any_instance_of(described_class).to receive(:perform).and_raise(Service::AI::Agent::Run::TemporaryError)

        expect { ActiveJob::Base.execute job.serialize }
          .not_to change { described_class.working_on?(ticket) }
      end

      it 'does not set ticket ai_agent_running flag to false when job is retried' do
        allow_any_instance_of(described_class).to receive(:perform).and_raise(Service::AI::Agent::Run::TemporaryError)

        ticket && article

        expect { ActiveJob::Base.execute job.serialize }
          .not_to change { ticket.reload.ai_agent_running }
      end

      it 'removes AI agent from the list when job is retried enough times' do
        allow_any_instance_of(described_class).to receive(:perform).and_raise(Service::AI::Agent::Run::TemporaryError)

        4.times { ActiveJob::Base.execute job.serialize }

        expect {  ActiveJob::Base.execute job.serialize }
          .to change { described_class.working_on(ticket) }
          .to []
      end

      it 'sets ticket ai_agent_running flag to false when job is retried enough times' do
        ticket.update! ai_agent_running: true

        job

        allow_any_instance_of(described_class).to receive(:perform).and_raise(Service::AI::Agent::Run::TemporaryError)

        4.times { ActiveJob::Base.execute job.serialize }

        expect {  ActiveJob::Base.execute job.serialize }
          .to change { ticket.reload.ai_agent_running }
          .to false
      end
    end
  end

  describe '.working_on' do
    let(:other_ticket)   { create(:ticket) }
    let(:other_article)  { create(:ticket_article, ticket: other_ticket) }
    let(:other_ai_agent) { create(:ai_agent) }

    let(:other_job) do
      described_class.perform_later(
        other_ai_agent,
        other_ticket,
        other_article,
        changes:        nil,
        user_id:        nil,
        execution_type: nil,
        event_type:     nil,
      )
    end

    it 'returns empty array when no agents are working on the ticket' do
      expect(described_class.working_on(ticket)).to be_empty
    end

    it 'returns array with agent ID when an agent is working on the ticket' do
      job

      expect(described_class.working_on(ticket)).to contain_exactly(
        have_attributes(lock_key: end_with(ai_agent.id.to_s))
      )
    end

    context 'when multiple agents are working on the same ticket' do
      let(:other_ticket) { ticket }
      let(:other_article) { article }

      it 'returns both agents' do
        job
        other_job

        expect(described_class.working_on(ticket)).to contain_exactly(
          have_attributes(lock_key: end_with(ai_agent.id.to_s)),
          have_attributes(lock_key: end_with(other_ai_agent.id.to_s))
        )
      end

      it 'skips one of them when given as excluded' do
        job
        other_job

        expect(described_class.working_on(ticket, exclude: other_job)).to contain_exactly(
          have_attributes(lock_key: end_with(ai_agent.id.to_s)),
        )
      end
    end

    context 'when multiple agents are working on different tickets' do
      it 'returns agent ID working on a given ticket if agents are working on different tickets' do
        job
        other_job

        expect(described_class.working_on(ticket)).to contain_exactly(
          have_attributes(lock_key: end_with(ai_agent.id.to_s))
        )
      end
    end
  end

  describe '.update_ticket' do
    let(:ticket) { create(:ticket) }

    it 'updates ticket based on working AI agents' do
      allow(described_class).to receive(:working_on?).and_return(true)

      expect { described_class.update_ticket(ticket) }
        .to change { ticket.reload.ai_agent_running }
        .to true
    end

    it 'touches ticket if flag is updated' do
      allow(described_class).to receive(:working_on?).and_return(true)

      expect { described_class.update_ticket(ticket) }
        .to change { ticket.reload.updated_at }
    end

    it 'does not update ticket if flag is matching' do
      expect { described_class.update_ticket(ticket) }
        .not_to change { ticket.reload.updated_at }
    end
  end
end

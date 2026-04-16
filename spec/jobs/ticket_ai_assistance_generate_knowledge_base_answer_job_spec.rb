# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketAIAssistanceGenerateKnowledgeBaseAnswerJob, type: :job do
  describe '#lock_key' do
    let(:ticket)            { create(:ticket) }
    let(:user)              { create(:user) }
    let(:knowledge_base_id) { 123 }

    it 'uses ticket id, last article timestamp and knowledge base id' do
      create(:ticket_article, ticket:)
      job = described_class.new

      allow(job).to receive(:arguments).and_return([ticket, user, knowledge_base_id])

      expect(job.lock_key).to eq(
        "#{described_class.name}/#{ticket.id}/#{ticket.articles.last.created_at}/#{knowledge_base_id}"
      )
    end
  end

  describe '#perform' do
    let(:ticket)            { create(:ticket) }
    let(:user)              { create(:user) }
    let(:knowledge_base_id) { 123 }

    def perform
      described_class.perform_now(ticket, user, knowledge_base_id)
    end

    context 'when CreateKnowledgeBaseAnswer service returns' do
      before do
        allow_any_instance_of(Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer)
          .to receive(:execute)
          .and_return(nil)
      end

      it 'forwards given arguments to CreateKnowledgeBaseAnswer service', :aggregate_failures do
        allow(Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer).to receive(:new).and_call_original
        expect_any_instance_of(Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer).to receive(:execute)

        perform

        expect(Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer)
          .to have_received(:new)
          .with(ticket:, current_user: user, knowledge_base_id:)
      end
    end

    context 'when error is raised' do
      before do
        allow_any_instance_of(Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer)
          .to receive(:execute)
          .and_raise(StandardError, 'Something went wrong')

        allow(OnlineNotification).to receive(:add)
      end

      it 'creates an online notification and does not raise', :aggregate_failures do
        expect { perform }.not_to raise_error

        expect(OnlineNotification).to have_received(:add).with(
          hash_including(
            data: {
              error_message: 'Something went wrong',
              ticket_title:  ticket.title,
            }
          )
        )
      end
    end
  end
end

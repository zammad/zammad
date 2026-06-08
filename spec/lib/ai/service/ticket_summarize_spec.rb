# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Service::TicketSummarize do
  subject(:ai_service) { described_class.new(current_user:, context_data:) }

  let(:group)        { create(:group) }
  let(:current_user) { create(:user, groups: [group]) }
  let(:ticket)       { create(:ticket, group:) }
  let(:article)      { create(:ticket_article, ticket:) }

  let(:context_data) do
    {
      ticket:,
      articles: ticket.articles.without_system_notifications,
    }
  end

  let(:llm_response) do
    {
      'customer_request'     => 'Customer requested help with an issue.',
      'conversation_summary' => ['This is a summary of the conversation.'],
      'language'             => 'en-us',
    }
  end

  before do
    setup_ai_provider('zammad_ai')

    allow_any_instance_of(AI::Provider::ZammadAI)
      .to receive(:ask).and_return(llm_response)
  end

  it 'passes through received ticket summary' do
    result = ai_service.execute
    expect(result.content).to include(llm_response)
  end

  context 'when conversation_summary is a string' do
    let(:llm_response) do
      {
        'customer_request'     => 'Customer requested help with an issue.',
        'conversation_summary' => 'This is a summary of the conversation.',
        'language'             => 'en-us',
      }
    end

    it 'converts it to an array' do
      result = ai_service.execute
      expect(result.content['conversation_summary']).to eq(['This is a summary of the conversation.'])
    end
  end

  context 'when result is missing a required key' do
    let(:llm_response) do
      {
        'summary' => 'This is a summary of the conversation.',
      }
    end

    it 'raises an error' do
      expect { ai_service.execute }
        .to raise_error(AI::Service::TicketSummarize::InvalidResultKeysError)
    end
  end

  context 'when result is missing all of the optional keys' do
    let(:llm_response) do
      {
        'language' => 'en-us',
        'summary'  => 'This is a summary of the conversation.',
      }
    end

    it 'raises an error' do
      expect { ai_service.execute }
        .to raise_error(AI::Service::TicketSummarize::InvalidResultKeysError)
    end
  end
end

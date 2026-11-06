# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/field_scope_examples'

RSpec.describe Service::AI::Tool::GetKnowledgeBaseAnswer, :aggregate_failures do
  let(:knowledge_base) { create(:knowledge_base) }
  let(:category)       { create(:knowledge_base_category, knowledge_base:) }
  let(:agent)          { create(:agent, preferences: { locale: 'en-us' }) }
  let(:answer)         { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Refunds for annual plans' }) }
  let(:english)        { answer.translations.first.tap { |translation| translation.content.update!(body: 'Within 30 days of a renewal, a full refund is possible.') } }
  let(:german) do
    kb_locale = create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'de-de'))
    create(:knowledge_base_answer_translation, answer:, kb_locale:, title: 'Erstattungen für Jahresabos').tap do |translation|
      translation.content.update!(body: 'Innerhalb von 30 Tagen nach der Verlängerung ist eine volle Erstattung möglich.')
    end
  end

  before { english }

  def perform(arguments, user: agent)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'get_knowledge_base_answer', arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user:, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS)
  end

  it 'is offered to an agent in the harness while a knowledge base is active' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).to include(described_class)

    knowledge_base.update!(active: false)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
  end

  it 'reads the answer in the agent\'s locale, as the row every tool returns, with its text marked' do
    result = perform({ answer_id: answer.id })

    expect(result.content[:answer]).to eq(
      type: 'KnowledgeBase::Answer', id: answer.id, title: 'Refunds for annual plans', locale: 'en-us', visibility: 'public',
      edited_at: english.edited_at, text: 'Within 30 days of a renewal, a full refund is possible.', truncated: false,
    )
    expect(result.text).to eq(<<~TEXT.chomp)
      Knowledge base answer #{answer.id} · en-us · public · updated #{Service::AI::Tool::Output.time(english.edited_at)}
      <text source="knowledge_base" field="title">
      │ Refunds for annual plans
      </text>
      <text source="knowledge_base" answer="#{answer.id}">
      │ Within 30 days of a renewal, a full refund is possible.
      </text>
    TEXT
  end

  it 'reads the locale asked for, and falls back where the answer has none' do
    german

    expect(perform({ answer_id: answer.id, locale: 'de-de' }).content[:answer]).to include(locale: 'de-de', title: 'Erstattungen für Jahresabos')
    expect(perform({ answer_id: answer.id, locale: 'fr-fr' }).content[:answer]).to include(locale: 'en-us')
  end

  it 'cuts a long text and says how much of it is shown' do
    english.content.update!(body: 'A long answer. ' * 600)

    expect(perform({ answer_id: answer.id }).content[:answer]).to include(truncated: true, part: 'start', full_length: 8_999)
  end

  it 'answers an answer the user may not see, and one that is gone, as not found' do
    not_found = { error: 'not_found', message: Service::AI::Tool::NOT_FOUND_MESSAGE }
    draft     = create(:knowledge_base_answer, category:)

    expect(perform({ answer_id: draft.id }).content).to eq(not_found)
    expect(perform({ answer_id: 0 }).content).to eq(not_found)
  end

  context 'when an MCP client reads it' do
    let(:editor)   { create(:admin, preferences: { locale: 'en-us' }) }
    let(:internal) { create(:knowledge_base_answer, :internal, category:) }
    let(:draft)    { create(:knowledge_base_answer, category:) }
    let(:archived) { create(:knowledge_base_answer, :archived, category:) }

    def call(arguments, permissions: %w[ticket.agent knowledge_base.editor], user: editor)
      token = create(:token, user:, preferences: { permission: permissions })

      Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user:, token:).to_h
    end

    def readable(permissions)
      [answer, internal, draft, archived].reject { |record| call({ answer_id: record.id }, permissions:)[:isError] }
    end

    before do
      Setting.set('http_type', 'https')
      Setting.set('fqdn', 'support.example.com')
    end

    it 'is offered to an agent\'s token while a knowledge base is active' do
      token = create(:token, user: agent, preferences: { permission: %w[ticket.agent] })

      expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    end

    it 'returns the answer with its link, fitting its output schema' do
      result = call({ answer_id: answer.id })
      url    = "https://support.example.com/#knowledge_base/#{knowledge_base.id}/locale/en-us/answer/#{answer.id}"

      expect(result[:structuredContent]).to include('answer' => include('id' => answer.id, 'visibility' => 'public', 'url' => url))
      expect(result.dig(:content, 0, :text)).to end_with("Links:\nKnowledge base answer #{answer.id} · en-us: #{url}")
      expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    end

    it 'reads what an editor\'s token may read, drafts included' do
      expect(readable(%w[ticket.agent knowledge_base.editor])).to eq([answer, internal, draft, archived])
    end

    it 'reads no draft and no archived answer with an editor\'s token that lists the reader permission only' do
      expect(readable(%w[ticket.agent knowledge_base.reader])).to eq([answer, internal])
      expect(JSON.parse(call({ answer_id: draft.id }, permissions: %w[ticket.agent knowledge_base.reader]).dig(:content, 0, :text)))
        .to eq('error' => 'not_found', 'message' => Service::AI::Tool::NOT_FOUND_MESSAGE)
    end

    it 'reads the published answers only, without their editorial dates, with a token that lists no knowledge base permission' do
      expect(readable(%w[ticket.agent])).to eq([answer])
      expect(call({ answer_id: answer.id }, permissions: %w[ticket.agent])[:structuredContent]['answer']).not_to have_key('edited_at')
    end
  end

  context 'with an agent without knowledge base access' do
    let(:reader) { create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])]) }

    it_behaves_like 'an AI tool returning only the fields the reader may see' do
      let(:tool_result) { perform({ answer_id: answer.id }, user: reader) }
    end
  end
end

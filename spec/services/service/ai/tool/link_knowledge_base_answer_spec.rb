# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::LinkKnowledgeBaseAnswer, :aggregate_failures do
  let(:group)          { create(:group) }
  let(:editor)         { create(:admin, groups: [group], preferences: { locale: 'en-us' }) }
  let(:ticket)         { create(:ticket, group:, title: 'VPN outage at the branch office') }
  let(:knowledge_base) { create(:knowledge_base) }
  let(:category)       { create(:knowledge_base_category, knowledge_base:) }
  let(:answer)         { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Reconnect the branch VPN' }) }
  let(:english)        { answer.translations.first }
  let(:german) do
    kb_locale = create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'de-de'))
    create(:knowledge_base_answer_translation, answer:, kb_locale:, title: 'Das Filial-VPN neu verbinden')
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  def call(arguments, permissions: %w[ticket.agent knowledge_base.editor], user: editor, context: nil)
    token = create(:token, user:, preferences: { permission: permissions })

    Service::MCPServer::CallTool.execute(tool: described_class, arguments: { ticket_number: ticket.number, answer_id: answer.id }.merge(arguments),
                                         user:, token:, server_context: context).to_h
  end

  def text(result)
    result[:content].first[:text]
  end

  # How get_ticket names the answers linked to the ticket.
  def linked_answers
    token  = create(:token, user: editor, preferences: { permission: %w[ticket.agent knowledge_base.editor] })
    result = Service::MCPServer::CallTool.execute(tool: Service::AI::Tool::GetTicket, arguments: { ticket_id: ticket.id, response_format: 'detailed' }, user: editor, token:).to_h

    result[:structuredContent].dig('references', 'knowledge_base_answers').map { |row| row.slice('id', 'locale', 'link') }
  end

  it "is offered to an agent's token over MCP only, while a knowledge base is active, as an idempotent write that destroys nothing" do
    token = create(:token, user: editor, preferences: { permission: %w[ticket.agent] })
    knowledge_base

    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: editor, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: editor, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
    annotations = Service::MCPServer::ToolDefinition.execute(tool: described_class, user: editor, token:).annotations
    expect(annotations.to_h).to eq(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)

    knowledge_base.update!(active: false)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: editor, surface: :mcp, token:)).not_to include(described_class)
  end

  it 'links the answer to the ticket, from its text, which get_ticket lists' do
    result = call({})
    url    = "https://support.example.com/#knowledge_base/#{knowledge_base.id}/locale/en-us/answer/#{answer.id}"

    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to eq(
      'ticket'        => { 'id' => ticket.id, 'number' => ticket.number, 'url' => "https://support.example.com/#ticket/zoom/#{ticket.id}" },
      'answer'        => { 'type' => 'KnowledgeBase::Answer', 'id' => answer.id, 'title' => 'Reconnect the branch VPN', 'locale' => 'en-us', 'url' => url },
      'linked_before' => false,
    )
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(text(result)).to start_with("Knowledge base answer #{answer.id} (en-us) is now linked to ticket #{ticket.number}.")
    expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id))
      .to contain_exactly(include('link_object' => 'KnowledgeBase::Answer::Translation', 'link_object_value' => english.id, 'link_type' => 'normal'))
    expect(linked_answers).to eq([{ 'id' => answer.id, 'locale' => 'en-us', 'link' => 'normal' }])
  end

  it 'links the text in the locale asked for' do
    translation = german

    expect(call({ locale: 'de-de' })[:structuredContent]['answer']).to include('title' => 'Das Filial-VPN neu verbinden', 'locale' => 'de-de')
    expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id).pluck('link_object_value')).to eq([translation.id])
  end

  it 'links the text in the user\'s locale where the answer has none in the locale asked for, and says so' do
    result = call({ locale: 'de-de' })

    expect(result[:structuredContent]['answer']).to include('locale' => 'en-us')
    expect(text(result)).to include('It has no text in de-de, so its en-us text was taken.')
    expect(Link.list(link_object: 'Ticket', link_object_value: ticket.id).pluck('link_object_value')).to eq([english.id])
    expect(text(call({ locale: 'en-us' }))).not_to include('It has no text in')
  end

  it 'changes nothing where the two are linked already, also from the knowledge base view the other way round' do
    Service::Link::Add.execute(source: ticket, target: english, type: 'normal')

    result = call({})

    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to include('linked_before' => true)
    expect(text(result)).to include('is linked to ticket', 'already; nothing was changed')
    expect(Link.count).to eq(1)
  end

  it 'finds no answer the token may not read, nor one that does not exist, and links no ticket the user may only read' do
    draft = create(:knowledge_base_answer, category:)
    readable = create(:ticket, group: create(:group))
    editor.group_ids_access_map = { group.id => 'full', readable.group_id => 'read' }

    expect(text(call({ answer_id: draft.id }, permissions: %w[ticket.agent knowledge_base.reader]))).to include('not_found')
    expect(text(call({ answer_id: 0 }))).to include('not_found')
    expect(text(call({ ticket_number: readable.number }))).to include('read_only')
    expect(Link.count).to eq(0)
  end

  it 'links nothing for a request cancelled already, although it asks for no confirmation' do
    context = instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } }, request_state: nil,
                                                  input_responses: nil, input_response: nil, cancelled?: true)

    expect(call({}, context:)[:isError]).to be(true)
    expect(Link.count).to eq(0)
  end

  it_behaves_like 'an AI tool loading a named ticket' do
    let(:tool)              { described_class }
    let(:user)              { editor }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
    let(:tool_arguments)    { { answer_id: answer.id } }
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::LinkTickets, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:token)  { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket) { create(:ticket, group:, title: 'VPN outage at the branch office') }
  let(:other)  { create(:ticket, group:, title: 'VPN down since this morning') }

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  def call(arguments, user: agent, context: nil)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments: { ticket_number: ticket.number, other_ticket_number: other.number }.merge(arguments), user:, token:,
                                         server_context: context).to_h
  end

  def text(result)
    result[:content].first[:text]
  end

  # How get_ticket names the links of a ticket.
  def links_of(object)
    result = Service::MCPServer::CallTool.execute(tool: Service::AI::Tool::GetTicket, arguments: { ticket_id: object.id, response_format: 'detailed' }, user: agent, token:).to_h

    result[:structuredContent].dig('references', 'tickets').to_h { |row| [row['id'], row['link']] }
  end

  it "is offered to an agent's token over MCP only, as an idempotent write that destroys nothing" do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)

    annotations = Service::MCPServer::ToolDefinition.execute(tool: described_class, user: agent, token:).annotations
    expect(annotations.to_h).to eq(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false)
  end

  it 'links the other ticket as what it is to the named one, which get_ticket reads back from both' do
    result = call({ link: 'parent' })

    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to eq(
      'ticket'        => { 'id' => ticket.id, 'number' => ticket.number, 'url' => "https://support.example.com/#ticket/zoom/#{ticket.id}" },
      'other_ticket'  => { 'id' => other.id, 'number' => other.number, 'url' => "https://support.example.com/#ticket/zoom/#{other.id}" },
      'link'          => 'parent',
      'linked_before' => false,
    )
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(text(result)).to eq("Ticket #{other.number} is now the parent of ticket #{ticket.number}.")
    expect(links_of(ticket)).to eq(other.id => 'parent')
    expect(links_of(other)).to eq(ticket.id => 'child')
  end

  it 'names each ticket by its number, ID or link' do
    expect(call({ ticket_number: nil, ticket_id: ticket.id, other_ticket_number: nil, other_ticket_url: "https://support.example.com/#ticket/zoom/#{other.id}", link: 'child' })[:isError]).to be(false)
    expect(links_of(ticket)).to eq(other.id => 'child')
  end

  it 'changes nothing where the two are linked already, in either direction or of another kind, and names the kind they have' do
    call({ link: 'normal' })

    result = call({ ticket_number: other.number, other_ticket_number: ticket.number, link: 'parent' })

    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to include('link' => 'normal', 'linked_before' => true)
    expect(text(result)).to eq("Ticket #{ticket.number} is linked to ticket #{other.number} already; nothing was changed. A link is changed or removed in Zammad.")
    expect(Link.count).to eq(1)
  end

  it 'refuses one ticket named twice, a call without the other ticket, and a link to another system' do
    expect(text(call({ other_ticket_number: nil, other_ticket_id: ticket.id, link: 'normal' }))).to include('Name two different tickets')
    expect(text(call({ other_ticket_number: nil, link: 'normal' }))).to include('by its other_ticket_number, other_ticket_id or other_ticket_url')
    expect(text(call({ other_ticket_number: nil, other_ticket_url: 'https://elsewhere.example.com/#ticket/zoom/1', link: 'normal' })))
      .to include('other_ticket_url is no link to a ticket of this Zammad')
    expect(Link.count).to eq(0)
  end

  it 'links nothing for a request cancelled already, although it asks for no confirmation' do
    context = instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } }, request_state: nil,
                                                  input_responses: nil, input_response: nil, cancelled?: true)

    expect(call({ link: 'normal' }, context:)[:isError]).to be(true)
    expect(Link.count).to eq(0)
  end

  it 'links no ticket the user may only read, which it says, and finds none they may not see, whichever it is' do
    readable = create(:ticket, group: create(:group))
    hidden   = create(:ticket, group: create(:group))
    agent.group_ids_access_map = { group.id => 'full', readable.group_id => 'read' }

    expect(text(call({ ticket_number: readable.number, link: 'normal' }))).to include('read_only')
    expect(text(call({ ticket_number: hidden.number, link: 'normal' }))).to include('not_found')
    expect(text(call({ other_ticket_number: hidden.number, link: 'normal' }))).to include('not_found')
    expect(Link.count).to eq(0)

    expect(call({ other_ticket_number: readable.number, link: 'normal' })[:isError]).to be(false)
  end

  context 'when another call links the two at once', :ensure_threads_exited do
    self.use_transactional_tests = false

    include_context 'with a link call that pauses after looking for an existing link'

    # Committed, so without the email address and channel a group's factory adds.
    let(:group) { create(:group, email_address: nil) }

    after do
      customers = [ticket.customer_id, other.customer_id]
      Link.where(link_object_source_value: [ticket.id, other.id]).delete_all
      Ticket.where(id: [ticket.id, other.id]).destroy_all
      User.where(id: customers).destroy_all
      Token.where(id: token.id).delete_all
      User.where(id: agent.id).destroy_all
      Group.where(id: group.id).destroy_all
      # Set by the file's before, committed here.
      Setting.reset('http_type')
      Setting.reset('fqdn')
    end

    it 'links them once, without waiting forever, where both link them the other way round over MCP' do
      first, second = link_concurrently(-> { call({ link: 'parent' }) }, -> { call({ ticket_number: other.number, other_ticket_number: ticket.number, link: 'normal' }) })

      expect(first[:structuredContent]).to include('link' => 'parent', 'linked_before' => false)
      expect(second[:structuredContent]).to include('link' => 'child', 'linked_before' => true)
      expect(Link.where(link_object_source_value: [ticket.id, other.id]).count).to eq(1)
    end

    it 'links them once where the ticket view links them while an MCP client does' do
      first, second = link_concurrently(-> { Service::Link::Add.execute(source: ticket, target: other, type: 'normal') }, -> { call({ link: 'child' }) })

      expect(first).to be_a(Link)
      expect(second[:structuredContent]).to include('link' => 'normal', 'linked_before' => true)
      expect(Link.where(link_object_source_value: [ticket.id, other.id]).count).to eq(1)
    end
  end

  it_behaves_like 'an AI tool loading a named ticket' do
    let(:tool)              { described_class }
    let(:user)              { agent }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
    let(:tool_arguments)    { { other_ticket_number: other.number, link: 'normal' } }
  end
end

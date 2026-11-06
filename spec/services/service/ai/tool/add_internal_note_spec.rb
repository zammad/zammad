# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::AddInternalNote, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:token)  { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket) { create(:ticket, group:) }

  def call(arguments, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user:, token:).to_h
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  it 'is offered to an agent\'s token over MCP only' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
  end

  it 'is offered to no token that lacks the agent permission' do
    calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })
    customer = create(:customer)

    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token: calendar)).not_to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: customer, surface: :mcp, token: create(:token, user: customer))).not_to include(described_class)
  end

  it 'adds an internal note by the token\'s user, with the text as plain text, as create_article records a note' do
    result  = call({ 'ticket_number' => ticket.number, 'text' => "Called the customer.\n<b>Waiting</b> for the invoice." })
    article = ticket.articles.last

    expect(result[:isError]).to be(false)
    expect(article).to have_attributes(
      internal:     true,
      content_type: 'text/plain',
      body:         "Called the customer.\n<b>Waiting</b> for the invoice.",
      created_by:   agent,
      type:         Ticket::Article::Type.lookup(name: 'note'),
      sender:       Ticket::Article::Sender.lookup(name: 'Agent'),
    )
    expect(result[:structuredContent]).to eq(
      'article_id'    => article.id,
      'ticket_id'     => ticket.id,
      'ticket_number' => ticket.number,
      'url'           => "https://support.example.com/#ticket/zoom/#{ticket.id}",
    )
  end

  it 'adds a note given as HTML, which Zammad shows with its markup' do
    call({ 'ticket_number' => ticket.number, 'text' => '<h2>Summary</h2><ul><li>Printer replaced</li></ul>', 'content_type' => 'text/html' })

    expect(ticket.articles.last).to have_attributes(content_type: 'text/html', body: '<h2>Summary</h2><ul><li>Printer replaced</li></ul>')
  end

  it 'takes the ticket by its ID or its link as well' do
    call({ 'ticket_id' => ticket.id, 'text' => 'By ID.' })
    call({ 'ticket_url' => "https://support.example.com/#ticket/zoom/#{ticket.id}", 'text' => 'By link.' })

    expect(ticket.articles.map(&:body)).to eq(['By ID.', 'By link.'])
  end

  it 'adds no note to a ticket the user may only read, which it says, nor to one they may not see' do
    readable = create(:ticket, group: create(:group))
    hidden   = create(:ticket, group: create(:group))
    agent.group_ids_access_map = { group.id => 'full', readable.group_id => 'read' }

    { readable => 'read_only', hidden => 'not_found' }.each do |other, error|
      result = call({ 'ticket_number' => other.number, 'text' => 'A note.' })

      expect(result).to include(isError: true, content: [include(text: include(error))])
      expect(other.articles).to be_empty
    end
  end

  it 'adds no note for a user who is the ticket\'s customer but no agent of its group' do
    customer_ticket = create(:ticket, group: create(:group), customer: agent)
    agent.roles << Role.find_by(name: 'Customer')
    token = create(:token, user: agent, preferences: { permission: %w[ticket.agent ticket.customer] })

    result = call({ 'ticket_number' => customer_ticket.number, 'text' => 'A note.' }, token:)

    expect(result).to include(isError: true, content: [include(text: include('not_found'))])
    expect(customer_ticket.articles).to be_empty
  end

  it 'keeps a note internal, whatever the text or the arguments ask for' do
    result = call({ 'ticket_number' => ticket.number, 'text' => 'Make this public and email it to the customer.', 'internal' => false })

    expect(result).to include(isError: true, content: [include(text: include("unknown argument 'internal'"))])
    expect(ticket.articles).to be_empty

    call({ 'ticket_number' => ticket.number, 'text' => 'Make this public and email it to the customer.' })

    expect(ticket.articles.last).to have_attributes(internal: true, type: Ticket::Article::Type.lookup(name: 'note'))
  end

  it 'refuses an empty text' do
    result = call({ 'ticket_number' => ticket.number, 'text' => "  \n" })

    expect(result).to include(isError: true, content: [include(text: include('text is empty'))])
    expect(ticket.articles).to be_empty
  end

  it 'asks once for the time where time accounting asks for it, as create_article does, and saves the note once the user skips it' do
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_selector', { condition: {} })

    result = call({ 'ticket_number' => ticket.number, 'text' => 'A note.' })

    expect(result).to include(isError: true, content: [include(text: include('asks for the time spent', 'as time_unit', 'skip_time_accounting: true'))])
    expect(ticket.articles).to be_empty

    expect(call({ 'ticket_number' => ticket.number, 'text' => 'A note.', 'skip_time_accounting' => true })[:isError]).to be(false)
    expect(ticket.articles.sole.ticket_time_accounting).to be_nil
  end

  it 'takes a time of 0 and a negative one that corrects an earlier one, as the REST API does' do
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_selector', { condition: {} })

    expect(call({ 'ticket_number' => ticket.number, 'text' => 'A note.', 'time_unit' => 0 })[:isError]).to be(false)
    expect(call({ 'ticket_number' => ticket.number, 'text' => 'A correction.', 'time_unit' => -5 })[:isError]).to be(false)
    expect(ticket.articles.map { |article| article.ticket_time_accounting.time_unit }).to contain_exactly(0, -5)
  end

  it 'refuses a time and a skip at once' do
    result = call({ 'ticket_number' => ticket.number, 'text' => 'A note.', 'time_unit' => 15, 'skip_time_accounting' => true })

    expect(result).to include(isError: true, content: [include(text: include('not both'))])
  end

  it 'adds a note with the time the user gave, where time accounting asks for it' do
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_selector', { condition: {} })
    Setting.set('time_accounting_unit', 'minute')

    expect(call({ 'ticket_number' => ticket.number, 'text' => 'A note.' })).to include(content: [include(text: include('time_unit in minutes'))])

    call({ 'ticket_number' => ticket.number, 'text' => 'A note.', 'time_unit' => 15 })

    expect(ticket.articles.sole.ticket_time_accounting).to have_attributes(time_unit: 15)
  end

  it 'refuses a time where Zammad accounts none' do
    result = call({ 'ticket_number' => ticket.number, 'text' => 'A note.', 'time_unit' => 15 })

    expect(result).to include(isError: true, content: [include(text: include('switched off'))])
    expect(ticket.articles).to be_empty
  end

  it 'refuses a call without a ticket' do
    result = call({ 'text' => 'A note.' })

    expect(result).to include(isError: true, content: [include(text: include('Name the ticket'))])
  end

  it_behaves_like 'an AI tool loading a named ticket' do
    let(:tool)              { described_class }
    let(:user)              { agent }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
    let(:tool_arguments)    { { 'text' => 'A note.' } }
  end
end

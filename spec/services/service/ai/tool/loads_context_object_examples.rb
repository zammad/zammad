# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The permission cases of a tool that loads the conversation's starting object, run through the permission check.
#
# Needs: `tool` (the tool class), `user` (allowed to run it), `readable_object` (the user may see it),
#   `unreadable_object` (the user may not see it); optional `tool_arguments`.
RSpec.shared_examples 'an AI tool loading its object' do
  let(:tool_arguments) { {} }

  def perform_tool(context_object)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: tool.tool_name, arguments: tool_arguments)

    Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user:, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS, context_object:)
  end

  let(:not_found) { { error: 'not_found', message: Service::AI::Tool::NOT_FOUND_MESSAGE } }

  it 'runs on a starting object the user may see' do
    expect(perform_tool(Gql::ZammadSchema.id_from_object(readable_object))).to have_attributes(status: 'ok')
  end

  it 'answers a starting object the user may not see as not found' do
    expect(perform_tool(Gql::ZammadSchema.id_from_object(unreadable_object)).content).to eq(not_found)
  end

  it 'answers a deleted starting object as not found, like one the user may not see' do
    gid = Gql::ZammadSchema.id_from_object(readable_object)
    readable_object.destroy!

    expect(perform_tool(gid).content).to eq(not_found)
  end

  it 'says so in a conversation without a starting object of its type' do
    type = tool.tool_loads[:type].name.underscore.humanize(capitalize: false)

    [nil, Gql::ZammadSchema.id_from_internal_id(Calendar, 1)].each do |context_object|
      expect(perform_tool(context_object).content).to eq(error: 'not_found', message: "This conversation is about no #{type}.")
    end
  end
end

# The permission cases of a tool whose ticket the caller names, over MCP: named by its number, its ID or a link, a ticket
#   the user may not see reads as one that does not exist.
#
# Needs: `tool` (the tool class, offered over MCP), `user` (allowed to run it), `readable_object` (a ticket the user may
#   see), `unreadable_object` (a ticket the user may not see); optional `tool_arguments`.
RSpec.shared_examples 'an AI tool loading a named ticket' do
  let(:tool_arguments) { {} }
  let(:not_found)      { { error: 'not_found', message: Service::AI::Tool::NOT_FOUND_MESSAGE } }

  def perform_named(ticket_arguments, user: self.user, permissions: [tool.tool_permission])
    token     = create(:token, user:, preferences: { permission: permissions })
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: tool.tool_name, arguments: tool_arguments.merge(ticket_arguments))

    Service::AI::Tool::Runtime::PerformCall.execute(user:, tool_call:, surface: :mcp, token:)
  end

  def names_of(ticket)
    { ticket_number: ticket.number, ticket_id: ticket.id, ticket_url: "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#ticket/zoom/#{ticket.id}" }
  end

  # One example per name, as a write tool may answer a second call on the same ticket otherwise.
  %i[ticket_number ticket_id ticket_url].each do |name|
    it "runs on a ticket the user may see, named by its #{name.to_s.humanize(capitalize: false)}" do
      expect(perform_named(names_of(readable_object).slice(name))).to have_attributes(status: 'ok')
    end
  end

  it 'answers a ticket the user may not see as not found, as one that does not exist, however it is named', :aggregate_failures do
    names_of(unreadable_object).each do |name, value|
      expect(perform_named({ name => value }).content).to eq(not_found), name.to_s
    end

    expect(perform_named({ ticket_number: '000' }).content).to eq(not_found)
    expect(perform_named({ ticket_id: 0 }).content).to eq(not_found)
    expect(perform_named({ ticket_url: names_of(readable_object)[:ticket_url].sub(%r{\d+\z}, '0') }).content).to eq(not_found)
  end

  # The only case that tells reading as an agent apart from reading at all: in another group, the customer may see it,
  #   with a token that lists the customer's permission too.
  it 'answers a ticket the user sees only as its customer as not found, however it is named', :aggregate_failures do
    both  = create(:agent_and_customer)
    owned = create(:ticket, customer: both, group: create(:group))

    names_of(owned).each do |name, value|
      expect(perform_named({ name => value }, user: both, permissions: [tool.tool_permission, 'ticket.customer']).content).to eq(not_found), name.to_s
    end
  end
end

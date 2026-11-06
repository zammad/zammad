# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Runtime::PerformCall, :aggregate_failures do
  let(:audience) { AI::Harness::Audience::HUMAN_AGENTS }
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:ticket)   { create(:ticket, group:, title: 'Printer on fire') }
  let(:runs)     { [] }

  # Reads a ticket with the policy, as the tools of the harness do.
  let(:tool) do
    calls = runs

    stub_const('Service::AI::Tool::ReadTicketTitle', Class.new(Service::AI::Tool) do
      description 'Read the title of a ticket.'
      effect      :read
      permission  'ticket.agent'
      offered_in  :harness
      audiences   :human_agents

      parameter :ticket_id, type: :integer, description: 'The ticket.', required: true

      define_method(:execute) do
        calls << current_user.id

        ticket = Ticket.find(arguments['ticket_id'])
        Pundit.authorize(current_user, ticket, :agent_read_access?)

        Service::AI::Tool::Runtime::Result.ok({ title: ticket.title }, text: "Title: #{ticket.title}")
      end
    end)
  end

  def perform(name: tool.tool_name, arguments: { 'ticket_id' => ticket.id }, user: agent, audience: self.audience, tool_names: nil, run: nil)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name:, arguments:)

    described_class.execute(user:, tool_call:, surface: :harness, audience:, tool_names:, run:)
  end

  it 'runs an offered tool as the user' do
    expect(perform).to have_attributes(status: 'ok', content: { title: 'Printer on fire' }, text: 'Title: Printer on fire')
    expect(runs).to eq([agent.id])
  end

  it 'takes the arguments with symbol keys too' do
    expect(perform(arguments: { ticket_id: ticket.id })).to have_attributes(status: 'ok')
  end

  context 'when the tool may not run here' do
    it 'refuses a tool that does not exist' do
      expect(perform(name: 'read_scanner').content).to eq(error: 'unknown_tool', message: "There is no tool called 'read_scanner'.")
    end

    it 'refuses a tool that is not offered in the harness' do
      tool.offered_in :mcp

      expect(perform.content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end

    it 'refuses a tool outside the run\'s audience' do
      expect(perform(audience: AI::Harness::Audience.new(name: :customers)).content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end

    it 'refuses a tool that declares no permission' do
      tool.tool_permission = nil

      expect(perform.content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end
  end

  context 'with the names of the tools the caller offered' do
    it 'runs a tool among them' do
      expect(perform(tool_names: [tool.tool_name, 'get_ticket'])).to have_attributes(status: 'ok')
      expect(runs).to eq([agent.id])
    end

    it 'refuses a tool outside them as unknown, although the router offers it' do
      expect(perform(tool_names: ['get_ticket']).content).to eq(error: 'unknown_tool', message: "There is no tool called '#{tool.tool_name}'.")
      expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience:)).to include(tool)
      expect(runs).to be_empty
    end

    it 'still refuses a tool among them that the router does not offer' do
      tool.offered_in :mcp

      expect(perform(tool_names: [tool.tool_name]).content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end
  end

  context 'when the user may not use the tool' do
    it 'refuses it without a user' do
      expect(perform(user: nil).content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end

    it 'refuses it to a user without its permission' do
      expect(perform(user: create(:customer)).content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end

    it 'refuses the very next call once the permission is revoked' do
      expect(perform).to have_attributes(status: 'ok')

      User.find(agent.id).update!(roles: Role.where(name: 'Customer'))

      expect(perform.content).to include(error: 'unknown_tool')
      expect(runs).to eq([agent.id])
    end

    # The permission check caches per request or job; a change made by another request does not clear this one's cache.
    it 'refuses the very next call once another request revoked the permission' do
      expect(perform).to have_attributes(status: 'ok')

      ActiveRecord::Base.connection.execute("DELETE FROM roles_users WHERE user_id = #{agent.id}")

      expect(perform.content).to include(error: 'unknown_tool')
      expect(runs).to eq([agent.id])
    end

    # A job runs with the query cache on; a change made on another connection does not clear it.
    it 'refuses the very next call once another connection revoked the permission, with the query cache on' do
      ActiveRecord::Base.cache do
        expect(perform).to have_attributes(status: 'ok')

        ActiveRecord::Base.connection.raw_connection.exec("DELETE FROM roles_users WHERE user_id = #{agent.id}")

        expect(perform.content).to include(error: 'unknown_tool')
      end
      expect(runs).to eq([agent.id])
    end

    it 'refuses it once the user is no longer active' do
      User.find(agent.id).update!(active: false)

      expect(perform.content).to include(error: 'unknown_tool')
      expect(runs).to be_empty
    end
  end

  it 'refuses a write, which cannot be confirmed yet' do
    tool.effect :write

    expect(perform.content).to include(error: 'unknown_tool')
    expect(runs).to be_empty
  end

  context 'with arguments that do not fit' do
    it 'quotes a broken call back and asks for a JSON object' do
      expect(perform(arguments: '{"ticket_id": 4').content).to eq(
        error:   'invalid_arguments',
        message: 'The arguments are no JSON object: {"ticket_id": 4. Call the tool again with its arguments as one JSON object.',
      )
      expect(runs).to be_empty
    end

    it 'never runs a broken call, also for a tool without required parameters' do
      tool.tool_parameters = {}

      expect(perform(arguments: '[4]').content).to include(error: 'invalid_arguments', message: start_with('The arguments are no JSON object: [4].'))
      expect(runs).to be_empty
    end

    it 'cuts a long broken call in the quote' do
      expect(perform(arguments: 'x' * 2_000).content[:message].length).to be < 700
    end

    it 'names missing, unknown and mistyped arguments' do
      expect(perform(arguments: { 'ticket_id' => '4', 'colour' => 'red' }).content)
        .to eq(error: 'invalid_arguments', message: "unknown argument 'colour'; argument 'ticket_id' must be of type integer")
      expect(perform(arguments: nil).content).to eq(error: 'invalid_arguments', message: "missing required argument 'ticket_id'")
      expect(runs).to be_empty
    end
  end

  context 'when the tool hits something the user may not see' do
    it 'answers a missing object and one without access alike' do
      missing   = perform(arguments: { 'ticket_id' => 0 })
      forbidden = perform(arguments: { 'ticket_id' => create(:ticket).id })

      expect(missing.content).to eq(error: 'not_found', message: 'The requested object was not found.')
      expect(forbidden.content).to eq(missing.content)
    end
  end

  context 'when the call comes over MCP' do
    let(:admin) { create(:admin, groups: [group]) }
    let(:token) { create(:token, user: admin, preferences: { permission: %w[ticket.agent] }) }

    let(:mcp_tool) do
      stub_const('Service::AI::Tool::ReadAdminRights', Class.new(Service::AI::Tool) do
        description 'Says whether the user may administrate.'
        effect      :read
        permission  'ticket.agent'
        offered_in  :mcp
        audiences   :human_agents

        def execute
          { admin: current_user.permissions?('admin') }
        end
      end)
    end

    def perform_over_mcp(name: mcp_tool.tool_name, user: admin, token: self.token)
      tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name:, arguments: {})

      described_class.execute(user:, tool_call:, surface: :mcp, token:)
    end

    it 'runs a tool offered over MCP, with the limits of the token wherever the tool asks' do
      expect(perform_over_mcp).to have_attributes(status: 'ok', content: { admin: false })
    end

    it 'refuses a tool that the token does not allow' do
      calendar = create(:token, user: admin, preferences: { permission: %w[user_preferences.calendar] })

      expect(perform_over_mcp(token: calendar).content).to include(error: 'unknown_tool')
    end

    it 'refuses a tool that is offered in the harness only' do
      expect(perform_over_mcp(name: tool.tool_name).content).to include(error: 'unknown_tool')
    end

    it 'leaves the token of the caller\'s context as it was' do
      perform_over_mcp

      expect(UserInfo.current_token).to be_nil
    end
  end

  it 'answers an unexpected failure without its message' do
    allow(Ticket).to receive(:find).and_raise(RuntimeError, 'PG::ConnectionBad: secret host')
    allow(Rails.logger).to receive(:error)

    expect(perform.content).to eq(error: 'execution_failed', message: 'The tool read_ticket_title failed. Try another way, or tell the user that it failed.')
    expect(Rails.logger).to have_received(:error).with(%r{secret host})
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Runtime::Router, :aggregate_failures do
  let(:audience) { AI::Harness::Audience::HUMAN_AGENTS }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }

  def define_tool(name, &)
    stub_const("Service::AI::Tool::#{name}", Class.new(Service::AI::Tool) do
      description 'A tool for the spec.'
      effect      :read
      permission  'ticket.agent'
      offered_in  :harness
      audiences   :human_agents

      def execute
        {}
      end

      class_eval(&) if block_given?
    end)
  end

  describe '.tools' do
    it 'knows a tool by its class alone' do
      tool = define_tool('ReadPrinter')

      expect(described_class.tools).to include(tool)
      expect(described_class.find('read_printer')).to be(tool)
      expect(described_class.find('read_scanner')).to be_nil
    end

    it 'forgets a tool class that is no longer reachable by its name' do
      tool = define_tool('RemovedTool')
      hide_const('Service::AI::Tool::RemovedTool')

      expect(described_class.tools).not_to include(tool)
    end
  end

  describe '.offered?' do
    it 'offers a declared tool in the harness to its audience' do
      expect(described_class.offered?(define_tool('ReadPrinter'), surface: :harness, user: agent, audience:)).to be(true)
    end

    it 'does not offer a write, which the harness cannot have confirmed yet' do
      expect(described_class.offered?(define_tool('UpdatePrinter') { effect :write }, surface: :harness, user: agent, audience:)).to be(false)
      anywhere = define_tool('UpdateAnywhere') do
        effect :write
        offered_in :harness, :mcp
      end

      expect(described_class.offered?(anywhere, surface: :harness, user: agent, audience:)).to be(false)
    end

    it 'does not offer a tool that is only for the MCP server' do
      expect(described_class.offered?(define_tool('ReadPrinter') { offered_in :mcp }, surface: :harness, user: agent, audience:)).to be(false)
    end

    it 'offers a tool that needs the run in the harness, and not where it is offered elsewhere too' do
      anywhere = define_tool('ReadRunAnywhere') do
        needs_run
        offered_in :harness, :mcp
      end

      expect(described_class.offered?(define_tool('ReadRun') { needs_run }, surface: :harness, user: agent, audience:)).to be(true)
      expect(described_class.offered?(anywhere, surface: :harness, user: agent, audience:)).to be(false)
    end

    it 'does not offer a tool that cannot work on this system' do
      tool = define_tool('ReadPrinter') { define_singleton_method(:available?) { false } }

      expect(described_class.offered?(tool, surface: :harness, user: agent, audience:)).to be(false)
    end

    it 'does not offer a tool outside the audience' do
      other_audience = AI::Harness::Audience.new(name: :customers)

      expect(described_class.offered?(define_tool('ReadPrinter'), surface: :harness, user: agent, audience: other_audience)).to be(false)
    end

    it 'does not offer a tool to a user who is inactive, missing or without its permission' do
      tool = define_tool('ReadPrinter')

      expect(described_class.offered?(tool, surface: :harness, user: create(:agent, active: false), audience:)).to be(false)
      expect(described_class.offered?(tool, surface: :harness, user: nil, audience:)).to be(false)
      expect(described_class.offered?(tool, surface: :harness, user: customer, audience:)).to be(false)
    end

    it 'does not offer a tool that misses a declaration' do
      expect(described_class.offered?(define_tool('ReadPrinter') { self.tool_permission = nil }, surface: :harness, user: agent, audience:)).to be(false)
    end
  end

  describe '.offered? over MCP' do
    let(:token) { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }

    def define_mcp_tool(name, &)
      define_tool(name) do
        offered_in :mcp
        class_eval(&) if block_given?
      end
    end

    it 'offers a declared tool offered over MCP, with no audience to name' do
      expect(described_class.offered?(define_mcp_tool('ReadPrinter'), user: agent, surface: :mcp, token:)).to be(true)
    end

    it 'does not offer a tool that is offered in the harness only' do
      expect(described_class.offered?(define_tool('ReadPrinter'), user: agent, surface: :mcp, token:)).to be(false)
    end

    it 'offers a write, which the client confirms with its user' do
      expect(described_class.offered?(define_mcp_tool('UpdatePrinter') { effect :write }, user: agent, surface: :mcp, token:)).to be(true)
    end

    it 'does not offer a write whose permission the token does not list' do
      calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

      expect(described_class.offered?(define_mcp_tool('UpdatePrinter') { effect :write }, user: agent, surface: :mcp, token: calendar)).to be(false)
    end

    it 'does not offer a tool whose permission the token does not list, also with an empty list' do
      tool       = define_mcp_tool('ReadPrinter')
      calendar   = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })
      empty_list = create(:token, user: agent, preferences: { permission: [] })

      expect(described_class.offered?(tool, user: agent, surface: :mcp, token: calendar)).to be(false)
      expect(described_class.offered?(tool, user: agent, surface: :mcp, token: empty_list)).to be(false)
    end

    it 'does not offer a tool whose permission the user does not hold, whatever the token lists' do
      customer_token = create(:token, user: customer, preferences: { permission: %w[ticket.agent] })

      expect(described_class.offered?(define_mcp_tool('ReadPrinter'), user: customer, surface: :mcp, token: customer_token)).to be(false)
    end

    it 'does not offer a tool to a user who is no longer active' do
      inactive = create(:agent, active: false)

      expect(described_class.offered?(define_mcp_tool('ReadPrinter'), user: inactive, surface: :mcp, token: create(:token, user: inactive, preferences: { permission: %w[ticket.agent] }))).to be(false)
    end

    it 'leaves the token of the caller\'s context as it was' do
      other_token = create(:token, user: agent, preferences: { permission: %w[ticket.agent] })

      UserInfo.with_token(other_token) do
        described_class.offered?(define_mcp_tool('ReadPrinter'), user: agent, surface: :mcp, token:)

        expect(UserInfo.current_token).to eq(other_token)
      end
    end
  end

  describe '.offered_tools' do
    before do
      define_tool('ReadPrinter')
      define_tool('ReadSettings') { permission 'admin' }
      define_tool('ReadScanner') { offered_in :mcp }
      define_tool('UpdatePrinter') { effect :write }
    end

    it 'gives the offered tools the user holds the permission for' do
      names = described_class.offered_tools(surface: :harness, user: agent, audience:).map(&:tool_name)

      expect(names).to include('read_printer')
      expect(names).not_to include('read_settings', 'read_scanner', 'update_printer')
      expect(described_class.offered_tools(surface: :harness, user: customer, audience:)).to be_empty
    end

    it 'gives the tools offered over MCP that the user and the token hold the permission for' do
      token = create(:token, user: agent, preferences: { permission: %w[ticket.agent] })

      expect(described_class.offered_tools(user: agent, surface: :mcp, token:).map(&:tool_name)).to eq(%w[add_internal_note create_article create_ticket get_current_user get_organization get_overview_tickets get_shared_draft get_ticket get_ticket_articles get_ticket_fields get_ticket_history get_user link_tickets list_overviews list_tags read_attachment read_scanner save_shared_draft search_organizations search_tickets search_users send_shared_draft set_ticket_tags update_ticket])
    end

    it 'gives exactly the tools the permission check runs' do
      [agent, customer, create(:agent, active: false)].each do |user|
        offered = described_class.offered_tools(surface: :harness, user:, audience:).map(&:tool_name)
        runs    = described_class.tools.map(&:tool_name).reject do |name|
          tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name:, arguments: {})

          Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user:, tool_call:, audience:).content[:error] == 'unknown_tool'
        end

        expect(offered).to eq(runs)
      end
    end
  end
end

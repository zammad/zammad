# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'json_schemer'

# The rules every tool keeps, checked for each tool instead of a list kept by hand: a new tool needs no change here
#   unless it breaks one of them.
RSpec.describe 'Declarations of the AI tools' do # rubocop:disable RSpec/DescribeClass
  it 'knows every tool in the directory of the tool layer' do
    # Taken before the files are loaded below, so that the router has to find them on its own.
    known = Service::AI::Tool::Runtime::Router.tools

    tools = Rails.root.glob('app/services/service/ai/tool/**/*.rb')
      .map { |path| path.relative_path_from(Rails.root.join('app/services')).sub_ext('').to_s.camelize.constantize }
      .select { |klass| klass.is_a?(Class) && klass < Service::AI::Tool }

    expect(tools - known).to be_empty
  end

  it 'gives every tool a name of its own' do
    names = Service::AI::Tool::Runtime::Router.tools.map(&:tool_name)

    expect(names).to eq(names.uniq)
  end

  describe 'the tools always loaded' do
    def overfull_audiences(tools)
      AI::Harness::Audience::ALL.each_value.select do |audience|
        tools.count { |tool| tool.always_loaded? && tool.audience?(audience) } > Service::AI::Tool::ALWAYS_LOADED_PER_AUDIENCE
      end
    end

    it 'are at most five per audience' do
      expect(overfull_audiences(Service::AI::Tool::Runtime::Router.tools)).to be_empty
    end

    it 'counts a sixth of an audience as too many' do
      tools = Array.new(6) do
        Class.new(Service::AI::Tool) do
          audiences :human_agents
          always_loaded
        end
      end

      expect(overfull_audiences(tools).map(&:name)).to eq([:human_agents])
    end
  end

  describe 'a tool that needs the run of the harness', :aggregate_failures do
    def tool_offered_in(*surfaces)
      Class.new(Service::AI::Tool) do
        description 'A tool for the spec.'
        effect :read
        permission 'ticket.agent'
        offered_in(*surfaces)
        audiences :human_agents
        needs_run
      end
    end

    it 'is declared where it is offered in the harness only' do
      expect(tool_offered_in(:harness).declaration_errors).to be_empty
    end

    it 'is refused where it is offered anywhere else too' do
      expect(tool_offered_in(:harness, :mcp).declaration_errors).to eq(['needs the run, so it is offered in the harness only'])
      expect(tool_offered_in(:mcp).declaration_errors).to eq(['needs the run, so it is offered in the harness only'])
    end

    it 'is no need for a tool that does not say so' do
      expect(Class.new(tool_offered_in(:harness, :mcp)) { self.tool_needs_run = false }.declaration_errors).to be_empty
    end
  end

  describe 'a tool that works on the starting object of the conversation', :aggregate_failures do
    def tool_offered_in(*surfaces)
      Class.new(Service::AI::Tool) do
        description 'A tool for the spec.'
        effect :read
        permission 'ticket.agent'
        offered_in(*surfaces)
        audiences :human_agents
        loads :ticket, type: Ticket
      end
    end

    it 'is declared where it is offered in the harness only' do
      expect(tool_offered_in(:harness).declaration_errors).to be_empty
    end

    it 'is refused where it is offered over MCP, which has no conversation' do
      expect(tool_offered_in(:harness, :mcp).declaration_errors).to eq(['loads the starting object, so it is offered in the harness only'])
    end

    it 'is declared over MCP too where the caller may name the object' do
      named = Class.new(tool_offered_in(:harness, :mcp)) { loads :ticket, type: Ticket, named: true }

      expect(named.declaration_errors).to be_empty
    end
  end

  # Offering a tool over MCP makes it part of a public interface: it is added here on purpose, never by accident.
  it 'offers exactly these tools over MCP' do
    expect(Service::AI::Tool::Runtime::Router.tools.select { |tool| tool.offered_in?(:mcp) }.map(&:tool_name)).to eq(%w[add_internal_note create_article create_ticket get_current_user get_knowledge_base_answer get_organization get_overview_tickets get_shared_draft get_ticket get_ticket_articles get_ticket_fields get_ticket_history get_user link_knowledge_base_answer link_tickets list_overviews list_tags read_attachment save_shared_draft search_knowledge_base search_organizations search_tickets search_users send_shared_draft set_ticket_tags update_ticket])
  end

  Service::AI::Tool::Runtime::Router.tools.select { |tool| tool.offered_in?(:mcp) }.each do |tool|
    describe "#{tool.name} over MCP", :aggregate_failures do
      it 'has a title and an output schema that is valid JSON Schema 2020-12' do
        expect(tool.tool_title).to be_present
        expect(tool.tool_output_schema).to be_present
        expect(JSONSchemer.schema(tool.tool_output_schema).valid_schema?).to be(true)
      end

      # A change of the definition is a change of the contract with every client: deliberate, and with the fixture.
      it 'keeps its MCP definition, as its snapshot pins it' do
        path       = Rails.root.join("spec/fixtures/files/mcp/tools/#{tool.tool_name}.json")
        definition = JSON.pretty_generate(Service::MCPServer::ToolDefinition.execute(tool:, user: nil, token: nil).to_h)
        path.write("#{definition}\n") if ENV['MCP_TOOL_SNAPSHOTS'] == 'write'

        expect(definition).to eq(path.read.chomp), "The MCP definition of #{tool.tool_name} changed. If on purpose, run with MCP_TOOL_SNAPSHOTS=write."
      end

      it 'describes itself without a conversation and names no tool that is not offered over MCP' do
        description = tool.description_for(:mcp)
        named       = Service::AI::Tool::Runtime::Router.tools.select { |other| description.match?(%r{\b#{other.tool_name}\b}) }

        expect(description).not_to match(%r{conversation}i)
        expect(named.reject { |other| other.offered_in?(:mcp) }.map(&:tool_name)).to be_empty
      end
    end
  end

  Service::AI::Tool::Runtime::Router.tools.each do |tool|
    describe tool.name do
      it 'declares a description, an effect, a permission, where it is offered and existing audiences' do
        expect(tool.declaration_errors).to be_empty
      end

      it 'declares a permission that exists' do
        expect(Permission.exists?(name: tool.tool_permission)).to be(true)
      end

      it 'is offered in the harness only when it needs the run' do
        expect(tool.tool_surfaces).to eq([:harness]) if tool.needs_run?
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::MCPServer::CallTool, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:token)  { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket) { create(:ticket, group:, title: 'Printer on fire') }

  let(:row_schema) { Service::AI::Tool::Output::Ticket::SCHEMA }

  let(:tool) do
    schema = { type: 'object', properties: { ticket: row_schema }, required: %w[ticket] }

    stub_const('Service::AI::Tool::ReadTicketRow', Class.new(Service::AI::Tool) do
      description 'Read a ticket as a row.'
      title       'Read ticket row'
      effect      :read
      permission  'ticket.agent'
      offered_in  :mcp
      audiences   :human_agents
      output_schema schema

      parameter :ticket_id, type: :integer, description: 'The ticket.', required: true

      def execute
        row = Service::AI::Tool::Output::Ticket.row(Ticket.find(argument(:ticket_id)))

        Service::AI::Tool::Runtime::Result.ok({ ticket: row.content }, text: row.text)
      end
    end)
  end

  def call(arguments, tool: self.tool)
    described_class.execute(tool:, arguments:, user: agent, token:).to_h
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  it 'returns the hash with its links as structured content, and the text with the links below it' do
    result = call({ ticket_id: ticket.id })
    url    = "https://support.example.com/#ticket/zoom/#{ticket.id}"

    expect(result[:structuredContent]).to include('ticket' => include('type' => 'Ticket', 'id' => ticket.id, 'url' => url))
    expect(result[:content]).to eq([{ type: 'text', text: "#{Service::AI::Tool::Output::Ticket.row(ticket).text}\n\nLinks:\nTicket #{ticket.number} (ID #{ticket.id}): #{url}\nCustomer (user #{ticket.customer_id}): https://support.example.com/#user/profile/#{ticket.customer_id}" }])
    expect(output_schema_errors(tool.tool_output_schema, result[:structuredContent])).to be_empty
    expect(result[:isError]).to be(false)
    expect(result[:_meta]).to include('io.modelcontextprotocol/serverInfo' => include(name: 'zammad'))
  end

  it 'answers an error as text alone, as clients check structured content against the schema even then' do
    result = call({ ticket_id: 0 })

    expect(result).to include(isError: true, content: [include(type: 'text', text: include('not_found'))])
    expect(result).not_to have_key(:structuredContent)
  end

  it 'returns text alone for a tool without an output schema' do
    tool.tool_output_schema = nil

    expect(call({ ticket_id: ticket.id })).not_to have_key(:structuredContent)
  end

  context 'when another write tool requests confirmation' do
    let(:tool) do
      stub_const('Service::AI::Tool::ConfirmPreference', Class.new(Service::AI::Tool) do
        description 'Confirm a preference change.'
        title 'Confirm preference'
        effect :write
        permission 'ticket.agent'
        offered_in :mcp
        audiences :human_agents

        def execute
          pending = confirmation.call(snapshot: { preference: 'locale', value: 'de-de', version: 1 },
                                      preview: 'Change language to German.', required: true)
          pending || Service::AI::Tool::Runtime::Result.ok({ confirmed: true })
        end
      end)
    end

    def confirm(state: nil)
      response = { action: 'accept', content: { confirm: true } } if state
      server_context = instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } },
                                       request_state: state, input_responses: response && { confirm: response }, input_response: response, cancelled?: false)
      described_class.execute(tool:, arguments: {}, user: agent, token:, server_context:).to_h
    end

    it 'uses the same dispatcher and continuation without article-specific arguments' do
      pending = confirm
      expect(pending[:resultType]).to eq('input_required')
      expect(pending.dig(:inputRequests, 'confirm', :params, :message)).to eq('Change language to German.')
      expect(confirm(state: pending[:requestState])).to include(isError: false, content: [include(text: include('confirmed'))])
    end
  end
end

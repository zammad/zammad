# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::MCPServer::ToolDefinition, :aggregate_failures do
  let(:agent) { create(:agent) }
  let(:token) { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }

  let(:tool) do
    stub_const('Service::AI::Tool::EchoText', Class.new(Service::AI::Tool) do
      description 'Echoes the text back.'
      effect      :read
      permission  'ticket.agent'
      offered_in  :mcp
      audiences   :human_agents

      parameter :text, type: :string, description: 'The text to echo.', required: true

      def execute
        Service::AI::Tool::Runtime::Result.ok({ text: argument(:text), user: current_user.login }, text: argument(:text))
      end
    end)
  end

  let(:definition) { described_class.execute(tool:, user: agent, token:) }

  it 'lists the tool with its name, description, input schema and every annotation of a read tool' do
    expect(definition.to_h).to include(
      name:        'echo_text',
      description: 'Echoes the text back.',
      inputSchema: include(type: 'object', properties: include(text: include(type: 'string')), required: ['text'], additionalProperties: false),
      annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
    )
  end

  it 'lists a write with the annotations of a tool that adds, so that the client asks before it calls it' do
    tool.effect :write

    expect(definition.to_h).to include(annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false })
  end

  it 'lists the title, the MCP sentences of the description and the output schema where the tool gives them' do
    tool.title 'Echo text'
    tool.description 'Echoes the text back.', mcp: 'For any client.'
    tool.output_schema({ type: 'object', properties: { text: { type: 'string' } } })

    expect(definition.to_h).to include(
      title:        'Echo text',
      description:  'Echoes the text back. For any client.',
      outputSchema: include(type: 'object', properties: { text: { type: 'string' } }),
    )
  end

  it 'runs a call through the permission check, as the token\'s user' do
    response = definition.call(text: 'hello', server_context: nil)

    expect(response.to_h).to include(content: [{ type: 'text', text: 'hello' }], isError: false)
  end

  it 'answers an error of the permission check as a result the model can act on' do
    response = definition.call(text: 42, server_context: nil)

    expect(response.to_h).to include(isError: true, content: [include(type: 'text', text: include('invalid_arguments'))])
  end
end

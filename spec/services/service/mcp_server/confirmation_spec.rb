# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::MCPServer::Confirmation, :aggregate_failures do
  let(:user)      { instance_double(User, id: 12) }
  let(:token)     { instance_double(Token, id: 34) }
  let(:tool_name) { 'update_priority' }
  let(:snapshot)  { { record_id: 56, version: 2, priority: 'high' } }
  let(:preview)   { 'Change priority from normal to high.' }

  def context(state: nil)
    response = { action: 'accept', content: { confirm: true } } if state
    instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } },
                    request_state: state, input_responses: response && { confirm: response }, input_response: response, cancelled?: false)
  end

  def confirm(state: nil, **)
    described_class.execute(user:, token:, tool_name:, snapshot:, preview:, required: true, server_context: context(state:), **)
  end

  it 'confirms a prepared action without depending on an article or ticket' do
    pending = confirm
    expect(pending.status).to eq('confirmation_required')
    expect(pending.text).to eq(preview)
    expect(confirm(state: pending.content.fetch(:request_state))).to be_nil
    expect(confirm(state: pending.content.fetch(:request_state)).ok?).to be(false)
  end

  it 'does not allow another tool or caller to reuse approval for the same snapshot and preview' do
    state = confirm.content.fetch(:request_state)
    [
      { tool_name: 'delete_record' },
      { user: instance_double(User, id: 13) },
      { token: instance_double(Token, id: 35) },
    ].each do |changed|
      expect(confirm(state:, **changed).ok?).to be(false)
    end
  end

  it 'binds approval to both the visible preview and the tool-owned snapshot' do
    state = confirm.content.fetch(:request_state)
    expect(confirm(state:, preview: 'Delete this record.').ok?).to be(false)
    expect(confirm(state:, snapshot: snapshot.merge(version: 3)).ok?).to be(false)
    expect(confirm(state:, required: false).ok?).to be(false)
  end

  it 'asks for values instead of a yes, binds them to the request and returns them once given' do
    fields  = { 'pending_time' => { type: 'string', format: 'date-time', title: 'Pending till' } }
    pending = confirm(fields:)
    given   = { action: 'accept', content: { pending_time: '2026-10-26T09:00:00Z', other: 'x' } }
    values  = instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } },
                                                  request_state: pending.content.fetch(:request_state), input_responses: { values: given }, cancelled?: false)
    allow(values).to receive(:input_response).with('values').and_return(given)

    expect(pending.content).to include(input_key: 'values', requested_schema: { type: 'object', properties: fields, required: ['pending_time'] })
    expect(described_class.execute(user:, token:, tool_name:, snapshot:, preview:, required: true, server_context: values, fields:)).to eq('pending_time' => '2026-10-26T09:00:00Z')
    expect(described_class.execute(user:, token:, tool_name:, snapshot:, preview:, required: true, server_context: values, fields:).ok?).to be(false)
  end

  it 'answers a decline with what the tool gives for it' do
    declined = Service::AI::Tool::Runtime::Result.error('missing_value', 'This change needs pending_time as well.')
    state    = confirm(declined:).content.fetch(:request_state)
    answer   = instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } },
                                                   request_state: state, input_responses: { confirm: { action: 'decline' } }, cancelled?: false)
    allow(answer).to receive(:input_response).with('confirm').and_return({ action: 'decline' })

    expect(described_class.execute(user:, token:, tool_name:, snapshot:, preview:, required: true, server_context: answer, declined:)).to eq(declined)
  end

  context 'when continuations arrive concurrently', :ensure_threads_exited do
    self.use_transactional_tests = false

    let(:approval) { AI::MCPConfirmation.last }

    after { approval.destroy! }

    it 'atomically consumes the approval once without an article version or ticket lock' do
      state = confirm.content.fetch(:request_state)
      approval
      with_uncommitted_concurrent_write(-> { confirm(state:) }) do |first|
        expect(first).to be_nil
        expect(confirm(state:).ok?).to be(false)
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::SaveSharedDraft, :aggregate_failures do
  let(:group)     { create(:group, email_address: create(:email_address)) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:colleague) { create(:agent, groups: [group], firstname: 'Carla', lastname: 'Second') }
  let(:token)     { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket)    { create(:ticket, group:) }
  let(:arguments) { { ticket_number: ticket.number, type: 'email', text: "Hello,\nthe fix ships tomorrow.", to: ['customer@example.com'] } }

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  def context(state: nil, response: nil, capabilities: { elicitation: { form: {} } })
    instance_double(MCP::ServerContext, modern?: true, client_capabilities: capabilities, request_state: state,
                    input_responses: response && { values: response }, input_response: response, cancelled?: false)
  end

  def accepted(state)
    context(state:, response: { action: 'accept', content: {} })
  end

  def call(arguments = self.arguments, context: nil, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user:, token:, server_context: context).to_h
  end

  def colleagues_draft
    UserInfo.with_user_id(colleague.id) do
      ticket.create_shared_draft!(new_article: { 'articleType' => 'note', 'type' => 'note', 'internal' => true, 'body' => '<p>Checked the logs, nothing yet.</p>' }, ticket_attributes: { 'state_id' => 2 })
    end
  end

  it "is offered to an agent's token over MCP only, as a destructive write of the closed world" do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token: create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] }))).not_to include(described_class)

    annotations = Service::MCPServer::ToolDefinition.execute(tool: described_class, user: agent, token:).annotations
    expect(annotations.to_h).to eq(readOnlyHint: false, destructiveHint: true, idempotentHint: false, openWorldHint: false)
  end

  it "saves the reply as the ticket's shared draft by the token's user, and sends nothing" do
    result = call(arguments.merge(cc: ['Alex <alex@example.com>'], subject: 'Your invoice'))

    draft = ticket.reload.shared_draft
    expect(draft).to have_attributes(created_by: agent, updated_by: agent, ticket_attributes: {})
    expect(draft.new_article).to eq(
      'articleType' => 'email', 'type' => 'email', 'internal' => false, 'body' => 'Hello,<br>the fix ships tomorrow.',
      'to' => 'customer@example.com', 'cc' => 'alex@example.com', 'subject' => 'Your invoice'
    )
    expect(ticket.articles).to be_empty
    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to eq(
      'shared_draft_id' => draft.id, 'ticket_id' => ticket.id, 'ticket_number' => ticket.number,
      'url' => "https://support.example.com/#ticket/zoom/#{ticket.id}", 'type' => 'email', 'internal' => false,
      'to' => 'customer@example.com', 'cc' => 'alex@example.com', 'outcome' => 'created'
    )
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(result[:content].first[:text]).to include('Nothing was sent')
  end

  it 'saves a note, internal, without recipients' do
    call({ ticket_id: ticket.id, type: 'note', text: 'Ask 2nd level about the logs.', internal: true })

    expect(ticket.reload.shared_draft.new_article).to eq('articleType' => 'note', 'type' => 'note', 'internal' => true, 'body' => 'Ask 2nd level about the logs.', 'to' => '', 'cc' => '')
  end

  it 'saves a draft given as HTML without the markup Zammad removes' do
    call({ ticket_id: ticket.id, type: 'note', text: '<p><b>Ask</b> 2nd level.</p><script>alert(1)</script>', content_type: 'text/html', internal: true })

    expect(ticket.reload.shared_draft.new_article['body']).to eq('<p><b>Ask</b> 2nd level.</p>')
  end

  it 'refuses a draft that breaks the rules of an article, and saves nothing' do
    {
      arguments.except(:to)                                                    => 'Email requires explicit to recipients',
      arguments.merge(to: ['not an address'])                                  => 'to contains an invalid email address',
      arguments.merge(subject: "One\nTwo")                                     => 'The subject must be one line',
      { ticket_id: ticket.id, type: 'note', text: 'A note.', subject: 'Hi' }   => 'Only email accepts cc or subject',
      { ticket_id: ticket.id, type: 'phone', text: 'A call.', to: ['+4911'] }  => 'omit to',
      { ticket_id: ticket.id, type: 'sms', text: 'Hi.', to: ['+49111111111'] } => 'no active matching channel',
      { ticket_id: ticket.id, type: 'whatsapp message', text: 'Hi.' }          => 'no active matching channel',
      { ticket_id: ticket.id, type: 'twitter status', text: 'Hi.' }            => "argument 'type' must be one of",
      arguments.merge(text: " \n")                                             => 'text is empty',
    }.each do |input, message|
      result = call(input)

      expect(result).to include(isError: true, content: [include(text: include(message))]), "#{input.inspect} gave #{result[:content]}"
    end
    expect(ticket.reload.shared_draft).to be_nil
  end

  it 'refuses email where the group has no active sender, as the interface offers none' do
    group.update!(email_address: nil)

    expect(call[:content].first[:text]).to include('no active email sender')
    expect(ticket.reload.shared_draft).to be_nil
  end

  context 'with an SMS ticket' do
    let(:channel) { create(:channel, area: 'Sms::Account', options: { adapter: 'sms/twilio', sender: '+49123456789' }) }
    let(:sms)     { { ticket_id: ticket.id, type: 'sms', text: 'The fix ships tomorrow.', to: ['+49111111111'] } }

    before { ticket.update!(preferences: { channel_id: channel.id }, create_article_type: Ticket::Article::Type.lookup(name: 'sms')) }

    it 'saves an SMS draft to one explicit number' do
      call(sms)

      expect(ticket.reload.shared_draft.new_article).to include('type' => 'sms', 'to' => '+49111111111')
    end

    it 'refuses what the channel could not send' do
      {
        sms.merge(to: ['+49 1'])   => 'exactly one explicit recipient phone number',
        sms.merge(text: 'a' * 161) => 'must not exceed 160 characters',
      }.each do |input, message|
        expect(call(input)[:content].first[:text]).to include(message)
      end
      ticket.update!(create_article_type: Ticket::Article::Type.lookup(name: 'email'))
      expect(call(sms)[:content].first[:text]).to include('not an SMS ticket')
      expect(ticket.reload.shared_draft).to be_nil
    end
  end

  it 'saves nothing where the ticket\'s group has shared drafts switched off' do
    group.update!(shared_drafts: false)

    result = call

    expect(result).to include(isError: true, content: [include(text: include('shared_drafts_off', 'add_internal_note'))])
    expect(ticket.reload.shared_draft).to be_nil
  end

  it 'saves no draft on a ticket the user may only read, which it says, nor on one they may not see' do
    readable = create(:ticket, group: create(:group))
    hidden   = create(:ticket, group: create(:group))
    agent.group_ids_access_map = { group.id => 'full', readable.group_id => 'read' }

    { readable => 'read_only', hidden => 'not_found' }.each do |other, error|
      result = call(arguments.merge(ticket_number: other.number))

      expect(result).to include(isError: true, content: [include(text: include(error))])
      expect(other.reload.shared_draft).to be_nil
    end
  end

  context 'with a shared draft a colleague saved' do
    let!(:existing) { colleagues_draft }

    it 'returns the draft that is there and saves nothing, where the client cannot ask' do
      [nil, context(capabilities: {})].each do |client|
        result = call(context: client)
        text   = result[:content].first[:text]

        expect(result[:isError]).to be(true)
        expect(text).to include('shared_draft_exists', 'Carla Second', existing.updated_at.utc.strftime('%Y-%m-%d %H:%M'), 'note, internal')
        expect(text).to include(%(<text source="agent" field="shared_draft">), 'Checked the logs, nothing yet.')
        expect(existing.reload.new_article['body']).to eq('<p>Checked the logs, nothing yet.</p>')
      end
      expect(call(context: context(capabilities: {}))[:content].first[:text]).to include("only once they agree, call again with replace_shared_draft_id: #{existing.id}.")
    end

    it 'replaces the draft by its ID once the user agreed in the conversation, where the client cannot ask, and gives its text back' do
      expect(call(arguments.merge(replace_shared_draft_id: existing.id + 1), context: context(capabilities: {}))[:content].first[:text]).to include('shared_draft_exists')
      expect(existing.reload.updated_by).to eq(colleague)

      result = call(arguments.merge(replace_shared_draft_id: existing.id), context: context(capabilities: {}))

      expect(result[:structuredContent]).to include('shared_draft_id' => existing.id, 'outcome' => 'replaced', 'replaced_text' => 'Checked the logs, nothing yet.')
      expect(result[:content].first[:text]).to include('The text it replaced:', %(<text source="agent" field="shared_draft">\n│ Checked the logs, nothing yet.\n</text>))
      expect(existing.reload).to have_attributes(updated_by: agent)
      expect(existing.new_article).to include('type' => 'email', 'to' => 'customer@example.com')
    end

    it 'takes no replace_shared_draft_id for the answer where the client shows the form, or where no client asks' do
      with_yes = arguments.merge(replace_shared_draft_id: existing.id)

      expect(call(with_yes, context: context)[:resultType]).to eq('input_required')
      state = call(with_yes, context: context).fetch(:requestState)
      expect(call(with_yes, context: context(state:, response: { action: 'decline' }))[:content].first[:text]).to include('shared_draft_exists').and(not_include('replace_shared_draft_id'))
      expect(call(with_yes)[:content].first[:text]).to include('shared_draft_exists').and(not_include('replace_shared_draft_id'))
      expect(existing.reload.updated_by).to eq(colleague)
    end

    it 'asks the user before it replaces the draft, and replaces it once' do
      pending = call(context: context)
      preview = pending.dig(:inputRequests, 'values', :params, :message)
      expect(pending[:resultType]).to eq('input_required')
      expect(pending.dig(:inputRequests, 'values', :params, :requestedSchema)).to eq(type: 'object', properties: {})
      expect(preview).to include("Replace the shared draft of ticket #{ticket.number}?", 'Carla Second', 'Checked the logs, nothing yet.', 'does not keep its ticket field changes', 'email, to customer@example.com', 'the fix ships tomorrow.')
      expect(existing.reload.updated_by).to eq(colleague)

      state  = pending.fetch(:requestState)
      result = call(context: accepted(state))

      expect(result[:structuredContent]).to include('shared_draft_id' => existing.id, 'outcome' => 'replaced', 'type' => 'email', 'replaced_text' => 'Checked the logs, nothing yet.')
      expect(existing.reload).to have_attributes(updated_by: agent, ticket_attributes: {})
      expect(existing.new_article).to include('type' => 'email', 'to' => 'customer@example.com')
      expect(call(context: accepted(state))[:isError]).to be(true)
    end

    it 'replaces nothing when the user declines or cancels, and gives the draft that is there' do
      [{ action: 'decline' }, { action: 'cancel' }].each do |response|
        state  = call(context: context).fetch(:requestState)
        result = call(context: context(state:, response:))

        expect(result[:content].first[:text]).to include('shared_draft_exists', 'Checked the logs, nothing yet.')
      end
      expect(existing.reload.updated_by).to eq(colleague)
    end

    it 'saves nothing when the draft was deleted after the question' do
      state = call(context: context).fetch(:requestState)
      existing.destroy!

      expect(call(context: accepted(state))[:content].first[:text]).to include('confirmation_required', 'changed since the user was asked')
      expect(ticket.reload.shared_draft).to be_nil
    end

    it 'asks again when the draft changed after the question' do
      state = call(context: context).fetch(:requestState)
      travel 1.minute
      UserInfo.with_user_id(colleague.id) { existing.update!(new_article: existing.new_article.merge('body' => '<p>Found it.</p>')) }

      expect(call(context: accepted(state))[:isError]).to be(true)
      expect(existing.reload.body).to eq('<p>Found it.</p>')
    end

    it "takes the draft's attachments with it" do
      create(:store, object: existing.class.name, o_id: existing.id, filename: 'logs.txt', preferences: { 'Content-Type' => 'text/plain' })

      pending = call(context: context)
      expect(pending.dig(:inputRequests, 'values', :params, :message)).to include('1 file')

      call(context: accepted(pending.fetch(:requestState)))
      expect(existing.reload.attachments).to be_empty
    end

    it 'asks again when only the attachments changed after the question' do
      original = create(:store, object: existing.class.name, o_id: existing.id, filename: 'original.txt', preferences: { 'Content-Type' => 'text/plain' })
      state    = call(context: context).fetch(:requestState)
      original.destroy!
      create(:store, object: existing.class.name, o_id: existing.id, filename: 'new-evidence.txt', preferences: { 'Content-Type' => 'text/plain' })

      expect(call(context: accepted(state))[:isError]).to be(true)
      expect(existing.reload.attachments.map(&:filename)).to eq(['new-evidence.txt'])
    end
  end

  it 'asks before it replaces a draft the user saved too, as the interface does' do
    call({ ticket_id: ticket.id, type: 'note', text: 'First version.' })

    expect(call(context: context)[:resultType]).to eq('input_required')
    expect(call[:content].first[:text]).to include('shared_draft_exists', agent.fullname, 'First version.')
  end

  it_behaves_like 'an AI tool loading a named ticket' do
    let(:tool)              { described_class }
    let(:user)              { agent }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
    let(:tool_arguments)    { arguments.except(:ticket_number) }
  end
end

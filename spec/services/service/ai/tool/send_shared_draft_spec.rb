# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::SendSharedDraft, :aggregate_failures do
  let(:group)     { create(:group, email_address: create(:email_address), signature: create(:signature, body: '<p>Configured signature</p>')) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:colleague) { create(:agent, groups: [group]) }
  let(:token)     { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket)    { create(:ticket, group:) }
  let(:body)      { '<p>Hello,</p><p>the fix ships tomorrow.</p>' }
  let(:article)   { { 'articleType' => 'email', 'type' => 'email', 'internal' => false, 'to' => 'customer@example.com', 'subject' => 'Your fix', 'body' => body } }
  let(:note)      { { 'type' => 'note', 'internal' => 'true', 'body' => '<p>Checked the logs.</p>' } }

  # Both interfaces keep the whole ticket form in a draft, changed or not, and form state besides.
  let(:form) { { 'id' => Gql::ZammadSchema.id_from_object(ticket), 'group_id' => group.id.to_s, 'state_id' => ticket.state_id, 'priority_id' => ticket.priority_id.to_s, 'owner_id' => '', 'pending_time' => nil, 'isDefaultFollowUpStateSet' => false } }

  def context(state: nil, response: nil)
    instance_double(MCP::ServerContext, modern?: true, client_capabilities: { elicitation: { form: {} } }, request_state: state,
                    input_responses: response && { confirm: response }, input_response: response, cancelled?: false)
  end

  def call(context = self.context, arguments: { ticket_number: ticket.number })
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:, server_context: context).to_h
  end

  def accepted(state)
    context(state:, response: { action: 'accept', content: {} })
  end

  def send_confirmed(arguments = { ticket_number: ticket.number })
    call(accepted(call(arguments:).fetch(:requestState)), arguments:)
  end

  def save_draft(new_article = article, ticket_attributes: form)
    UserInfo.with_user_id(colleague.id) do
      ticket.create_shared_draft!(new_article:, ticket_attributes:)
    end
  end

  def text_of(result)
    result[:content].first[:text]
  end

  it "is offered to an agent's token over MCP only, as a destructive write of the open world" do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)

    annotations = Service::MCPServer::ToolDefinition.execute(tool: described_class, user: agent, token:).annotations
    expect(annotations.to_h).to include(destructiveHint: true, openWorldHint: true)
  end

  it 'sends a draft the interface saved once the user confirmed it, with the signature, and deletes the draft' do
    save_draft

    pending = call
    expect(pending.dig(:inputRequests, 'confirm', :params, :message)).to include('customer@example.com', 'subject: ', 'the fix ships tomorrow.', 'Configured signature')
    expect(ticket.articles).to be_empty

    result = call(accepted(pending.fetch(:requestState)))

    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to include('type' => 'email', 'to' => 'customer@example.com', 'outcome' => 'queued')
    expect(ticket.articles.sole).to have_attributes(subject: include('Your fix'), body: include('the fix ships tomorrow.', 'Configured signature'), created_by: agent)
    expect(ticket.reload.shared_draft).to be_nil
  end

  it 'puts the signature where the editor left its place, before the quoted message' do
    save_draft(article.merge('body' => '<p>Hello,</p><div data-signature-placeholder="true"></div><blockquote type="cite">Earlier message</blockquote>'))

    send_confirmed

    sent = ticket.articles.sole.body
    expect(sent.index('Configured signature')).to be < sent.index('Earlier message')
  end

  it 'answers the message the draft replies to, as the interface keeps it' do
    replied = create(:ticket_article, :inbound_email, ticket:, message_id: '<question@example.com>')
    save_draft(article.merge('in_reply_to' => replied.message_id))

    send_confirmed

    expect(ticket.articles.last).to have_attributes(in_reply_to: '<question@example.com>')
  end

  it 'sends an internal note without asking, and deletes the draft' do
    save_draft(note)

    expect(call[:isError]).to be(false)
    expect(ticket.articles.sole).to have_attributes(internal: true, body: '<p>Checked the logs.</p>')
    expect(ticket.reload.shared_draft).to be_nil
  end

  it 'asks for the time where Zammad requires it, and accounts the time the user gave' do
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_selector', { condition: {} })
    save_draft(note)

    expect(text_of(call)).to include('asks for the time spent', 'as time_unit', 'skip_time_accounting: true')
    expect(ticket.articles).to be_empty

    call(arguments: { ticket_number: ticket.number, time_unit: 10 })
    expect(ticket.articles.sole.ticket_time_accounting).to have_attributes(time_unit: 10)
    expect(ticket.reload.shared_draft).to be_nil
  end

  it 'keeps the draft where the confirmation is declined, and says so' do
    save_draft

    declined = call(context(state: call.fetch(:requestState), response: { action: 'decline' }))

    expect(text_of(declined)).to include('declined the confirmation form without showing it', 'The shared draft stays on the ticket')
    expect(ticket.articles).to be_empty
    expect(ticket.reload.shared_draft).to be_present
  end

  it 'leaves a draft with files, inline images too, or with ticket field changes to Zammad' do
    draft = save_draft
    create(:store, object: draft.class.name, o_id: draft.id, filename: 'screenshot.png', preferences: { 'Content-ID' => 'shot@example.com', 'Content-Disposition' => 'inline' })
    expect(text_of(call)).to include('has files, which only Zammad sends along')

    draft.attachments.each(&:destroy!)
    draft.update!(ticket_attributes: form.merge('state_id' => Ticket::State.lookup(name: 'closed').id.to_s))
    expect(text_of(call)).to include('has ticket field changes, which only Zammad sends along')
    expect(ticket.articles).to be_empty
  end

  it 'leaves a draft the agent chose to sign or encrypt to Zammad, as either interface keeps the choice' do
    desktop = article.merge('security' => { 'method' => 'SMIME', 'options' => ['encryption'] })
    legacy  = article.merge('preferences' => { 'security' => { 'type' => 'PGP', 'sign' => { 'success' => true }, 'encryption' => {} } })

    [desktop, legacy].each do |secured|
      ticket.shared_draft&.destroy!
      save_draft(secured)

      expect(call).to include(isError: true, content: [include(text: include('not_supported', 'has signing or encryption'))])
      expect(ticket.reload.shared_draft).to be_present
    end
    expect(ticket.articles).to be_empty

    ticket.shared_draft.destroy!
    save_draft(article.merge('security' => { 'method' => 'SMIME', 'options' => [] }))
    expect(call).not_to include(isError: true)
  end

  it 'answers a ticket without a draft' do
    expect(text_of(call)).to include('has no shared draft')
  end

  it_behaves_like 'an AI tool loading a named ticket' do
    let(:tool)              { described_class }
    let(:user)              { agent }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
    let(:tool_arguments)    { {} }

    before { save_draft(note) }
  end
end

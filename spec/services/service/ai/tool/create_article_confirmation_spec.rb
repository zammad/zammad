# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::CreateArticle, :aggregate_failures, performs_jobs: true do
  let(:group)     { create(:group, email_address: create(:email_address)) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:token)     { create(:token, user: agent, preferences: { permission: ['ticket.agent'] }) }
  let(:ticket)    { create(:ticket, group:) }
  let(:arguments) { { ticket_id: ticket.id, type: 'email', text: 'The fix ships tomorrow.', to: ['customer@example.com'] } }

  def context(state: nil, response: nil, modern: true, capabilities: { elicitation: { form: {} } }, cancelled: false)
    instance_double(MCP::ServerContext, modern?: modern, client_capabilities: capabilities, request_state: state,
                    input_responses: response && { confirm: response }, input_response: response, cancelled?: cancelled)
  end

  def call(context = self.context, arguments: self.arguments, token: self.token)
    Service::MCPServer::CallTool.execute(tool: Service::AI::Tool::CreateArticle, arguments:, user: agent, token:, server_context: context).to_h
  end

  def accepted(state, **)
    context(state:, response: { action: 'accept', content: {} }, **)
  end

  it 'asks about the prepared message before creating any article or job' do
    result = call
    expect(result[:resultType]).to eq('input_required')
    expect(result.dig(:inputRequests, 'confirm', :params, :message)).to include('customer@example.com', group.email_address.email, arguments[:text])
    expect(result[:requestState]).to be_present
    expect(ticket.articles).to be_empty
    expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued
  end

  it 'sends exactly once after affirmative confirmation and refuses a repeated continuation' do
    state = call.fetch(:requestState)
    result = call(accepted(state))
    expect(result[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
    expect(call(accepted(state))[:isError]).to be(true)
    expect(ticket.articles.count).to eq(1)
  end

  [true, false].each do |include_signature|
    it "confirms the final email with include_signature=#{include_signature} and refuses changing it afterwards" do
      group.update!(signature: create(:signature, body: '<p>Configured signature</p>'))
      input = arguments.merge(include_signature:)
      result = call(arguments: input)
      preview = result.dig(:inputRequests, 'confirm', :params, :message)
      expect(preview.include?('Configured signature')).to be(include_signature)
      state = result.fetch(:requestState)

      expect(call(accepted(state), arguments: input.merge(include_signature: !include_signature))[:isError]).to be(true)
      expect(ticket.articles).to be_empty
      expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued

      expect { expect(call(accepted(state), arguments: input)[:isError]).to be(false) }
        .to have_enqueued_job(TicketArticleCommunicateEmailJob)
      expect(ticket.articles.last.body.include?('Configured signature')).to be(include_signature)
    end
  end

  it 'cannot reuse approval after the created internal email is deleted' do
    internal_email = arguments.merge(internal: true)
    state = call(arguments: internal_email).fetch(:requestState)
    expect(call(accepted(state), arguments: internal_email)[:isError]).to be(false)
    article = ticket.articles.last
    expect(Pundit.policy!(agent, article).destroy?).to be(true)
    article.destroy!

    expect { expect(call(accepted(state), arguments: internal_email)[:isError]).to be(true) }
      .not_to have_enqueued_job(TicketArticleCommunicateEmailJob)
    expect(ticket.articles).to be_empty
  end

  it 'rolls back approval consumption when article creation fails' do
    state = call.fetch(:requestState)
    allow(Service::Ticket::Article::Create).to receive(:execute).and_raise(StandardError, 'test failure')
    expect(call(accepted(state))[:isError]).to be(true)
    expect(AI::MCPConfirmation.last.consumed_at).to be_nil
    expect(ticket.articles).to be_empty

    allow(Service::Ticket::Article::Create).to receive(:execute).and_call_original
    expect(call(accepted(state))[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
  end

  it 'keeps approval valid after a channel fetch saves operational status' do
    freeze_time
    state = call.fetch(:requestState)
    channel = group.email_address.channel
    travel 30.seconds
    expect { channel.update!(preferences: channel.preferences.merge(last_fetch: Time.current), status_in: 'ok') }
      .to change(channel, :updated_at)

    expect(call(accepted(state))[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
  end

  it 'keeps approval valid when escalation recalculation only clears obsolete statistics' do
    freeze_time
    ticket.update_columns(escalation_at: 1.hour.from_now)
    state = call.fetch(:requestState)
    travel 30.seconds
    expect { ticket.escalation_calculation(true) }.to change(ticket, :updated_at)
    expect(ticket.escalation_at).to be_nil

    expect(call(accepted(state))[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
  end

  it 'shows readable recipient lists in the confirmation preview' do
    result = call(arguments: arguments.merge(to: ['customer@example.com', 'other@example.com'], cc: ['copy@example.com']))
    preview = result.dig(:inputRequests, 'confirm', :params, :message)
    expect(preview).to include("to: customer@example.com, other@example.com\n", "cc: copy@example.com\n")
  end

  it 'asks for nothing but the yes, and takes the Accept alone as it, as clients send it for such a form' do
    state = call.fetch(:requestState)

    expect(call.dig(:inputRequests, 'confirm', :params, :requestedSchema)).to eq(type: 'object', properties: {})
    expect(call(context(state:, response: { action: 'accept' }))[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
  end

  it 'keeps channel approval valid after unrelated channel delivery status changes' do
    channel = create(:channel, area: 'Sms::Account', options: { adapter: 'sms/twilio', sender: '+49123456789' })
    ticket.update!(preferences: { channel_id: channel.id }, create_article_type: Ticket::Article::Type.lookup(name: 'sms'))
    sms = { ticket_id: ticket.id, type: 'sms', text: 'A reply.', to: ['+49111111111'] }
    state = call(arguments: sms).fetch(:requestState)
    channel.update!(status_out: 'ok', last_log_out: '')

    expect(call(accepted(state), arguments: sms)[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
    expect(CommunicateSmsJob).to have_been_enqueued
  end

  it 'refuses approval if the email delivery adapter changes' do
    state = call.fetch(:requestState)
    channel = group.email_address.channel
    channel.options['outbound']['adapter'] = 'smtp'
    channel.save!

    expect(call(accepted(state))[:isError]).to be(true)
    expect(ticket.articles).to be_empty
  end

  it 'refuses approval if the configured sender changes or is deactivated' do
    state = call.fetch(:requestState)
    group.email_address.update!(email: 'another-sender@example.com')
    expect(call(accepted(state))[:isError]).to be(true)

    state = call.fetch(:requestState)
    group.email_address.channel.update!(active: false)
    expect(call(accepted(state))[:isError]).to be(true)
    expect(ticket.articles).to be_empty
  end

  it 'refuses approval if the ticket customer or state changes' do
    state = call.fetch(:requestState)
    ticket.update!(customer: create(:customer))
    expect(call(accepted(state))[:isError]).to be(true)

    state = call.fetch(:requestState)
    ticket.update!(state: Ticket::State.lookup(name: 'closed'))
    expect(call(accepted(state))[:isError]).to be(true)
    expect(ticket.articles).to be_empty
  end

  it 'ignores delivery bookkeeping on a selected message but rejects a different threading target' do
    source = create(:ticket_article, ticket:, type: Ticket::Article::Type.lookup(name: 'email'), message_id: 'source@example.com')
    reply = arguments.merge(reply_to_article_id: source.id)
    state = call(arguments: reply).fetch(:requestState)
    source.update!(preferences: { delivery_status: 'success', delivery_status_date: Time.current })
    expect(call(accepted(state), arguments: reply)[:isError]).to be(false)

    state = call(arguments: reply).fetch(:requestState)
    source.update!(message_id: 'changed@example.com')
    expect { call(accepted(state), arguments: reply) }.not_to change(Ticket::Article, :count)
  end

  it 'refuses declined, cancelled, absent and malformed responses' do
    [nil, {}, 'accept', { action: 'decline' }, { action: 'cancel' }, { action: 'Accept' }].each do |response|
      state = call.fetch(:requestState)
      expect(call(context(state:, response:))[:isError]).to be(true)
      expect(call(accepted(state))[:isError]).to be(true)
    end
    expect(ticket.articles).to be_empty
  end

  it 'answers a declined form with a client that may not have shown it, and offers the shared draft where the group has them' do
    message = ->(result) { result.dig(:content, 0, :text) }

    group.update!(shared_drafts: true)
    declined = call(context(state: call.fetch(:requestState), response: { action: 'decline' }))
    expect(message.call(declined)).to include('declined the confirmation form without showing it', 'save_shared_draft')

    group.update!(shared_drafts: false)
    declined = call(context(state: call.fetch(:requestState), response: { action: 'decline' }))
    expect(message.call(declined)).to include('declined the confirmation form without showing it')
    expect(message.call(declined)).not_to include('save_shared_draft')
    expect(ticket.articles).to be_empty
  end

  it 'rejects tampered, missing and expired continuation state' do
    state = call.fetch(:requestState)
    [nil, 'tampered', "#{state}x"].each do |invalid|
      expect(call(accepted(invalid))[:isError]).to be(true)
    end
    travel 11.minutes do
      expect(call(accepted(state))[:isError]).to be(true)
    end
    expect(ticket.articles).to be_empty
  end

  it 'binds the approval to exact arguments, prepared signature, sender and ticket' do
    state = call.fetch(:requestState)
    [arguments.merge(text: 'Changed'), arguments.merge(to: ['other@example.com']), arguments.merge(internal: true),
     arguments.merge(ticket_id: create(:ticket, group:).id)].each do |changed|
      expect(call(accepted(state), arguments: changed)[:isError]).to be(true)
    end
    group.update!(signature: create(:signature, body: '<p>A different signature</p>'))
    expect(call(accepted(state))[:isError]).to be(true)
    expect(ticket.articles).to be_empty
  end

  it 'binds the approval to the token and rechecks its permissions' do
    state = call.fetch(:requestState)
    other_token = create(:token, user: agent, preferences: { permission: ['ticket.agent'] })
    expect(call(accepted(state), token: other_token)[:isError]).to be(true)
    token.update!(preferences: { permission: ['user_preferences.calendar'] })
    expect(call(accepted(state))[:isError]).to be(true)
    expect(ticket.articles).to be_empty
  end

  it 'rechecks group permission after confirmation' do
    state = call.fetch(:requestState)
    agent.group_ids_access_map = { group.id => 'read' }
    expect(call(accepted(state))).to include(isError: true, content: [include(text: include('read_only'))])
    expect(ticket.articles).to be_empty
  end

  it 'invalidates approval after another article was added' do
    state = call.fetch(:requestState)
    create(:ticket_article, ticket:)
    expect { call(accepted(state)) }.not_to change(Ticket::Article, :count)
  end

  it 'never downgrades a continuation to the unsupported client path' do
    state = call.fetch(:requestState)
    expect(call(accepted(state, modern: false))[:isError]).to be(true)
    expect(call(accepted(state, capabilities: {}))[:isError]).to be(true)
    expect(call(accepted(state, cancelled: true))[:isError]).to be(true)
    expect(call(context(state: '', capabilities: {}))[:isError]).to be(true)
    expect(call(context(response: {}, modern: false))[:isError]).to be(true)
    expect(ticket.articles).to be_empty
  end

  it 'uses client tool approval for a first call without supported form elicitation' do
    [context(modern: false), context(capabilities: {}), context(capabilities: { elicitation: { url: {} } })].each do |unsupported|
      expect(call(unsupported)[:isError]).to be(false)
    end
    expect(ticket.articles.count).to eq(3)
  end

  it 'supports the bare elicitation capability and confirms internal email and public notes too' do
    expect(call(context(capabilities: { elicitation: {} }), arguments: arguments.merge(internal: true))[:resultType]).to eq('input_required')
    expect(call(arguments: { ticket_id: ticket.id, type: 'note', text: 'Public note' })[:resultType]).to eq('input_required')
    expect(call(arguments: { ticket_id: ticket.id, type: 'note', text: 'Internal note', internal: true })[:isError]).to be(false)
    expect(ticket.articles.count).to eq(1)
  end

  context 'when the same confirmation arrives concurrently', :ensure_threads_exited do
    self.use_transactional_tests = false

    let(:group) { create(:group, email_address: nil) }
    let(:ticket)    { create(:ticket, group:, customer: agent) }
    let(:arguments) { { ticket_id: ticket.id, type: 'note', text: 'One public note.' } }
    let(:approval)  { AI::MCPConfirmation.last }

    after do
      approval.destroy!
      ticket.destroy!
      token.destroy!
      agent.destroy!
      group.destroy!
    end

    it 'waits for the first write and refuses the duplicate after it commits' do
      state = call.fetch(:requestState)
      approval
      with_uncommitted_concurrent_write(-> { call(accepted(state)) }) do |first|
        expect(first[:isError]).to be(false)
        expect(call(accepted(state))[:isError]).to be(true)
      end
      expect(ticket.articles.count).to eq(1)
    end
  end
end

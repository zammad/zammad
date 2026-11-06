# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::CreateTicket, :aggregate_failures, performs_jobs: true do
  let(:group)     { create(:group, name: 'Support', email_address: create(:email_address)) }
  let(:level2)    { create(:group, name: '2nd Level', email_address: nil) }
  let(:agent)     { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [group, level2]) }
  let(:token)     { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:customer)  { create(:customer, firstname: 'Carla', lastname: 'Customer', email: 'carla@example.com') }
  let(:arguments) { { 'customer' => customer.email, 'title' => 'Printer broken', 'group' => 'Support', 'message' => 'note', 'text' => 'Carla called: the printer is broken.' } }

  def context(state: nil, response: nil, key: :confirm, capabilities: { elicitation: { form: {} } }, cancelled: false)
    instance_double(MCP::ServerContext, modern?: true, client_capabilities: capabilities, request_state: state,
                    input_responses: response && { key => response }, input_response: response, cancelled?: cancelled)
  end

  def call(given = {}, context: nil)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments: arguments.merge(given), user: agent, token:, server_context: context).to_h
  end

  def error_of(result)
    JSON.parse(result.dig(:content, 0, :text))
  end

  def created
    Ticket.find_by(title: 'Printer broken')
  end

  def first_message
    created.articles.reorder(:id).first
  end

  it 'is offered to an agent\'s token over MCP only' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
  end

  it "says in its description why a client cannot start a chat or a channel's ticket, and what replies on one" do
    expect(described_class.description_for(:mcp)).to include('Zammad cannot write the first message in a chat, a web form, WhatsApp, Telegram, SMS or Facebook: only the customer does')
  end

  it 'creates the ticket with an internal note as its first message, as the token\'s user, and names it with its link' do
    result = call

    expect(result[:isError]).to be(false)
    expect(created).to have_attributes(customer:, group:, state: Ticket::State.find_by(default_create: true), created_by_id: agent.id)
    expect(created.articles.sole).to have_attributes(type: Ticket::Article::Type.lookup(name: 'note'), internal: true, body: 'Carla called: the printer is broken.', created_by_id: agent.id)
    expect(result[:structuredContent]).to include('ticket_number' => created.number, 'message' => 'note', 'outcome' => 'saved', 'url' => end_with("#ticket/zoom/#{created.id}"))
  end

  it 'creates the first message given as HTML' do
    call({ 'text' => '<p>Carla called: the <b>printer</b> is broken.</p>', 'content_type' => 'text/html' })

    expect(first_message).to have_attributes(content_type: 'text/html', body: '<p>Carla called: the <b>printer</b> is broken.</p>')
  end

  it 'names a phone call received as the customer\'s, one placed as the agent\'s' do
    call({ 'message' => 'phone_in' })
    expect(first_message).to have_attributes(type: Ticket::Article::Type.lookup(name: 'phone'), sender: Ticket::Article::Sender.lookup(name: 'Customer'), internal: false, from: 'Carla Customer <carla@example.com>', to: 'Support')

    created.destroy!
    call({ 'message' => 'phone_out' })
    expect(first_message).to have_attributes(sender: Ticket::Article::Sender.lookup(name: 'Agent'), from: 'Nina Agent', to: 'Carla Customer <carla@example.com>')
  end

  describe 'the first message' do
    def call_without_message(given = {})
      Service::MCPServer::CallTool.execute(tool: described_class, arguments: arguments.except('message').merge(given), user: agent, token:, server_context: nil).to_h
    end

    it 'is the create form\'s default where none is asked for, a phone call received unless configured otherwise' do
      expect(call_without_message[:structuredContent]).to include('message' => 'phone_in')
      expect(first_message).to have_attributes(type: Ticket::Article::Type.lookup(name: 'phone'), sender: Ticket::Article::Sender.lookup(name: 'Customer'), internal: false)

      created.destroy!
      Setting.set('ui_ticket_create_default_type', 'email-out')
      expect(call_without_message({ 'to' => [customer.email] })[:structuredContent]).to include('message' => 'email', 'outcome' => 'queued')
    end

    it 'is the create form\'s first offered type where its default is not offered, as the form falls back' do
      Setting.set('ui_ticket_create_available_types', %w[phone-out email-out])

      expect(call_without_message[:structuredContent]).to include('message' => 'phone_out')
    end

    it 'is refused where the create form does not offer its type, with the ones it offers, the internal note always' do
      Setting.set('ui_ticket_create_available_types', %w[phone-in])

      expect(error_of(call({ 'message' => 'phone_out' }))).to include('error' => 'invalid_value', 'message' => include('Offered: phone_in, note.'))
      expect(created).to be_nil
      expect(call[:isError]).to be(false)
    end
  end

  it 'creates the ticket with its first message in one go, so that a trigger on a new ticket sees the message' do
    create(:trigger, condition: { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' }, 'article.sender_id' => { 'operator' => 'is', 'value' => Ticket::Article::Sender.lookup(name: 'Customer').id.to_s } },
                     perform:   { 'ticket.tags' => { 'operator' => 'add', 'value' => 'by-phone' } })

    call({ 'message' => 'phone_in' })

    expect(created.tag_list).to include('by-phone')
  end

  it 'creates the ticket where the group requires time accounting on changes' do
    Setting.set('time_accounting', true)

    expect(call[:isError]).to be(false)
    expect(created).to be_present
  end

  it 'takes the state, priority, owner and a custom field by name' do
    call({ 'state' => 'open', 'priority' => '3 high', 'owner' => 'me' })

    expect(created).to have_attributes(state: Ticket::State.lookup(name: 'open'), priority: Ticket::Priority.lookup(name: '3 high'), owner: agent)
  end

  it 'refuses an owner the group does not allow, with the groups they may own tickets in that the user has access to' do
    create(:agent, firstname: 'Ole', lastname: 'Second', email: 'ole@example.com', groups: [level2, create(:group, name: 'Secret')])

    expect(error_of(call({ 'owner' => 'ole@example.com' }))).to include('error' => 'not_allowed', 'message' => include('Ole Second (ole@example.com) may own tickets in: 2nd Level.'))
    expect(created).to be_nil
  end

  describe 'the customer' do
    it 'is found by ID, login or name as well' do
      ["ID #{customer.id}", customer.login, 'Carla Customer'].each do |name|
        call({ 'customer' => name })
        expect(created&.customer).to eq(customer), name
        created.destroy!
      end
    end

    it 'is refused where nobody fits, with the closest, and nobody is created' do
      result = call({ 'customer' => 'Carla Custmer' })

      expect(error_of(result)).to include('error' => 'invalid_value', 'message' => include('matches no user', 'Carla Customer (carla@example.com)'))
      expect(User.where(lastname: 'Custmer')).to be_empty
      expect(created).to be_nil
    end

    it 'is refused where the name fits only by a part, with the candidate, and nothing is created' do
      expect(error_of(call({ 'customer' => 'Carla' })))
        .to include('error' => 'ambiguous', 'message' => 'customer "Carla" fits only by a part: Carla Customer (carla@example.com). Use the email, or the ID where there is none.')
      expect(created).to be_nil
    end

    it 'is refused where several fit, with the candidates' do
      create(:customer, firstname: 'Carla', lastname: 'Other', email: 'carla.other@example.com')

      expect(error_of(call({ 'customer' => 'Carla' }))).to include('error' => 'ambiguous', 'message' => include('carla@example.com', 'carla.other@example.com'))
    end

    it 'is refused where an organization is named, with its members, none of them picked' do
      organization = create(:organization, name: 'Example Corp')
      customer.update!(organization:)

      result = call({ 'customer' => 'Example Corp' })

      expect(error_of(result)).to include('error' => 'ambiguous', 'message' => include('is an organization', 'Carla Customer (carla@example.com)'))
      expect(created).to be_nil
    end
  end

  it 'refuses an owner or a group that fits only by a part, with the candidate, and creates nothing' do
    expect(error_of(call({ 'owner' => 'Nin' }))).to include('error' => 'ambiguous', 'message' => include('owner "Nin" fits only by a part: Nina Agent'))
    expect(error_of(call({ 'group' => 'Supp' }))).to include('error' => 'ambiguous', 'message' => 'group "Supp" fits only by a part: Support. Use the full name.')
    expect(created).to be_nil
  end

  it 'refuses a group the user may not create tickets in, with the groups they may' do
    agent.group_names_access_map = { group.name => 'full', level2.name => 'read' }

    expect(error_of(call({ 'group' => '2nd Level' }))).to include('error' => 'invalid_value', 'message' => include('Support').and(not_include('2nd Level.')))
    expect(created).to be_nil
  end

  it 'creates nothing for a request cancelled already, also for a note that needs no confirmation' do
    expect(call(context: context(cancelled: true))[:isError]).to be(true)
    expect(created).to be_nil
  end

  context 'with a field the create screen requires', db_strategy: :reset do
    before do
      create(:object_manager_attribute_select, name: 'product', display: 'Product', data_option_options: { 'cloud' => 'Zammad Cloud', 'self' => 'Zammad Self-Hosted' },
                                                screens: { 'create_middle' => { 'ticket.agent' => { 'shown' => true, 'required' => true } } })
      ObjectManager::Attribute.migration_execute
    end

    it 'names it with its values where the client cannot ask, and creates nothing' do
      expect(error_of(call)).to include('error' => 'missing_value', 'message' => include('fields.product'))
      expect(created).to be_nil
    end

    it 'asks the user for it in a form, and creates the ticket with the answer' do
      asked = call(context: context)
      expect(asked[:resultType]).to eq('input_required')
      expect(asked.dig(:inputRequests, 'values', :params, :requestedSchema, :properties, 'fields.product', :enum)).to eq(['Zammad Cloud', 'Zammad Self-Hosted'])

      answer = context(state: asked[:requestState], key: :values, response: { action: 'accept', content: { 'fields.product' => 'Zammad Cloud' } })
      expect(call(context: answer)[:isError]).to be(false)
      expect(created.product).to eq('cloud')
    end

    it 'creates nothing where the user declines, also once the field is no longer required' do
      asked = call(context: context)
      create(:core_workflow, :active_and_screen, :perform_action, screen: 'create_middle', key: 'ticket.product', operator: 'set_optional', value: 'true')

      declined = context(state: asked[:requestState], key: :values, response: { action: 'decline' })
      expect(call(context: declined)[:isError]).to be(true)
      expect(created).to be_nil
    end

    it 'names a field the answer makes required, and creates nothing' do
      create(:object_manager_attribute_text, name: 'billing_code', display: 'Billing code', screens: { 'create_middle' => { 'ticket.agent' => { 'shown' => true, 'required' => false } } })
      ObjectManager::Attribute.migration_execute
      create(:core_workflow, :active_and_screen, :perform_action, screen: 'create_middle', key: 'ticket.billing_code', operator: 'set_mandatory', value: 'true',
                                                                  condition_selected: { 'ticket.product' => { operator: 'is', value: ['cloud'] } })

      asked  = call(context: context)
      answer = context(state: asked[:requestState], key: :values, response: { action: 'accept', content: { 'fields.product' => 'Zammad Cloud' } })

      expect(error_of(call(context: answer))).to include('error' => 'missing_value', 'message' => include('fields.billing_code'))
      expect(created).to be_nil
    end

    it 'asks again where an answer changes the signed email the user confirmed, and creates nothing' do
      group.update!(signature: create(:signature, body: '<p>Product: #{ticket.product}</p>')) # rubocop:disable Lint/InterpolationCheck
      email  = { 'message' => 'email', 'to' => ['carla@example.com'] }
      asked  = call(email, context: context)
      answer = context(state: asked[:requestState], key: :values, response: { action: 'accept', content: { 'fields.product' => 'Zammad Cloud', 'confirm' => true } })

      expect(error_of(call(email, context: answer))).to include('error' => 'confirmation_required', 'message' => include('"product":"Zammad Cloud"'))
      expect(created).to be_nil
    end

    it 'names a value the create screen does not allow' do
      create(:core_workflow, :active_and_screen, :perform_action, screen: 'create_middle', key: 'ticket.product', operator: 'remove_option', value: ['self'])

      expect(error_of(call({ 'fields' => { 'product' => 'Zammad Self-Hosted' } }))).to include('error' => 'not_allowed', 'message' => include('fields.product', 'Allowed: Zammad Cloud'))
    end
  end

  describe 'a first message the customer can read' do
    def accept(state)
      context(state:, response: { action: 'accept', content: { confirm: true } })
    end

    it 'saves a public phone call only once the user confirmed it' do
      asked = call({ 'message' => 'phone_in' }, context: context)

      expect(asked.dig(:inputRequests, 'confirm', :params, :message)).to include('Create a ticket "Printer broken" for Carla Customer (carla@example.com) in group Support?')
      expect(created).to be_nil
      expect(call({ 'message' => 'phone_in' }, context: accept(asked[:requestState]))[:isError]).to be(false)
      expect(first_message.internal).to be(false)
    end

    it 'sends an email only to the recipients named, after the confirmation' do
      email = { 'message' => 'email', 'to' => ['carla@example.com'] }
      asked = call(email, context: context)

      expect(asked.dig(:inputRequests, 'confirm', :params, :message)).to include('carla@example.com', group.email_address.email, 'subject: Printer broken').and(not_include('RE:'))
      expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued

      expect { call(email, context: accept(asked[:requestState])) }.to have_enqueued_job(TicketArticleCommunicateEmailJob)
      expect(first_message).to have_attributes(type: Ticket::Article::Type.lookup(name: 'email'), to: 'carla@example.com', subject: 'Printer broken')
      expect(first_message.preferences).not_to have_key('subtype')
    end

    it 'signs an email with the values the ticket gets, in the message confirmed and the one sent' do
      group.update!(signature: create(:signature, body: '<p>Owner: #{ticket.owner.fullname}; Priority: #{ticket.priority.name}</p>')) # rubocop:disable Lint/InterpolationCheck
      email = { 'message' => 'email', 'to' => ['carla@example.com'], 'owner' => 'me', 'priority' => '3 high' }
      asked = call(email, context: context)

      expect(asked.dig(:inputRequests, 'confirm', :params, :message)).to include('Owner: Nina Agent; Priority: 3 high')
      expect(call(email, context: accept(asked[:requestState]))[:isError]).to be(false)
      expect(first_message.body).to include('Owner: Nina Agent; Priority: 3 high')
    end

    it 'creates nothing where the user declines' do
      asked = call({ 'message' => 'phone_out' }, context: context)
      declined = context(state: asked[:requestState], response: { action: 'decline' })

      expect(call({ 'message' => 'phone_out' }, context: declined)[:isError]).to be(true)
      expect(created).to be_nil
    end

    it 'creates nothing where the email would go out over another delivery than the user confirmed' do
      email   = { 'message' => 'email', 'to' => ['carla@example.com'] }
      asked   = call(email, context: context)
      channel = group.email_address.channel
      channel.options['outbound']['adapter'] = 'smtp'
      channel.save!

      expect(call(email, context: accept(asked[:requestState]))[:isError]).to be(true)
      expect(created).to be_nil
    end

    it 'creates nothing where the user declines the email' do
      email = { 'message' => 'email', 'to' => ['carla@example.com'] }
      asked = call(email, context: context)

      expect(call(email, context: context(state: asked[:requestState], response: { action: 'decline' }))[:isError]).to be(true)
      expect(created).to be_nil
      expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued
    end

    it 'sends the email on the client\'s own approval where it cannot show a form' do
      expect { call({ 'message' => 'email', 'to' => ['carla@example.com'] }) }.to have_enqueued_job(TicketArticleCommunicateEmailJob)
      expect(created).to be_present
    end

    it 'refuses a confirmation for other values than it asked about' do
      asked = call({ 'message' => 'phone_in' }, context: context)

      expect(call({ 'message' => 'phone_in', 'text' => 'Something else.' }, context: accept(asked[:requestState]))[:isError]).to be(true)
      expect(created).to be_nil
    end

    it 'keeps the answer and creates nothing where the message cannot be saved' do
      asked = call({ 'message' => 'phone_in' }, context: context)
      allow(Service::Ticket::Article::Create).to receive(:execute).and_raise(ActiveRecord::RecordInvalid)

      expect(call({ 'message' => 'phone_in' }, context: accept(asked[:requestState]))[:isError]).to be(true)
      expect(created).to be_nil
      expect(AI::MCPConfirmation.where(consumed_at: nil)).to exist
    end

    it 'refuses an email to an invalid address' do
      expect(error_of(call({ 'message' => 'email', 'to' => ['not an address'] }))).to include('error' => 'invalid_arguments', 'message' => include('invalid email address'))
      expect(created).to be_nil
    end

    it 'refuses an email without recipients, or from a group without an email address' do
      expect(error_of(call({ 'message' => 'email' }))).to include('error' => 'invalid_arguments', 'message' => include('explicit to recipients'))
      expect(error_of(call({ 'message' => 'email', 'to' => ['carla@example.com'], 'group' => '2nd Level' }))).to include('message' => include('no active email sender'))
      expect(created).to be_nil
    end
  end
end

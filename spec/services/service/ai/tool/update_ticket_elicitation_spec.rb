# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Where a change needs what only the user can give, a client that can shows its user a form; update_ticket_spec holds
#   the change itself and its refusals.
RSpec.describe Service::AI::Tool::UpdateTicket, :aggregate_failures do
  let(:group)            { create(:group) }
  let(:agent)            { create(:agent, groups: [group]) }
  let(:token)            { create(:token, user: agent, preferences: { permission: ['ticket.agent'] }) }
  let(:ticket)           { create(:ticket, group:, state: Ticket::State.lookup(name: 'open')) }
  let(:pending_reminder) { { ticket_id: ticket.id, state: 'pending reminder' } }

  before { Setting.set('timezone_default', 'Europe/Berlin') }

  def context(state: nil, key: nil, response: nil, modern: true, capabilities: { elicitation: { form: {} } })
    responses = response && { key => response }

    instance_double(MCP::ServerContext, modern?: modern, client_capabilities: capabilities, request_state: state,
                                        input_responses: responses, cancelled?: false).tap do |double|
      allow(double).to receive(:input_response) { |name| responses&.dig(name.to_sym) }
    end
  end

  def call(context = self.context, arguments: pending_reminder)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:, server_context: context).to_h
  end

  def answered(state, content, key: :values, action: 'accept')
    context(state:, key:, response: { action:, content: })
  end

  describe 'a value Core Workflow requires' do
    it 'asks for the pending time with a form, and sets it once the user gives it' do
      pending = call
      request = pending.dig(:inputRequests, 'values', :params)

      expect(pending[:resultType]).to eq('input_required')
      expect(request[:message]).to eq("Ticket #{ticket.number}: this change needs Pending till as well.")
      expect(request[:requestedSchema]).to eq(type: 'object', properties: { 'pending_time' => { type: 'string', format: 'date-time', title: 'Pending till' } }, required: ['pending_time'])
      expect(ticket.reload.state.name).to eq('open')

      result = call(answered(pending[:requestState], { pending_time: '2026-10-26T09:00:00+01:00' }))

      expect(result[:isError]).to be(false)
      expect(ticket.reload).to have_attributes(state: Ticket::State.lookup(name: 'pending reminder'), pending_time: Time.utc(2026, 10, 26, 8))
    end

    it 'names what is missing when the user declines, changes nothing, and refuses the same continuation twice' do
      state = call[:requestState]

      expect(call(answered(state, nil, action: 'decline'))).to include(isError: true, content: [include(text: include('missing_value', 'pending_time (date and time, ISO 8601)'))])
      expect(call(answered(state, { pending_time: '2026-10-26T09:00:00+01:00' }))[:isError]).to be(true)
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'refuses a continuation for other arguments' do
      state = call[:requestState]

      result = call(answered(state, { pending_time: '2026-10-26T09:00:00+01:00' }), arguments: { ticket_id: ticket.id, state: 'pending close' })

      expect(result[:isError]).to be(true)
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'refuses the answer once the ticket changed meanwhile' do
      state = call[:requestState]
      ticket.update!(state: Ticket::State.lookup(name: 'closed'))

      expect(call(answered(state, { pending_time: '2026-10-26T09:00:00+01:00' }))[:isError]).to be(true)
      expect(ticket.reload.state.name).to eq('closed')
    end

    it 'takes no yes and no empty answer instead of the value, and no cancelled continuation' do
      state     = call[:requestState]
      cancelled = context(state:, key: :values, response: { action: 'accept', content: { pending_time: '2026-10-26T09:00:00+01:00' } })
      allow(cancelled).to receive(:cancelled?).and_return(true)

      expect(call(answered(state, { confirm: true }, key: :confirm))[:isError]).to be(true)
      expect(call(answered(call[:requestState], {}))).to include(isError: true, content: [include(text: include('Not every value was given'))])
      expect(call(cancelled)[:isError]).to be(true)
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'refuses an answer that is no time, and changes nothing' do
      state = call[:requestState]

      result = call(answered(state, { pending_time: 'next Monday' }))

      expect(result).to include(isError: true, content: [include(text: include('is no date and time'))])
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'names what is missing where the client cannot show a form' do
      [context(modern: false), context(capabilities: {})].each do |without_form|
        result = call(without_form)

        expect(result).to include(isError: true, content: [include(text: include('missing_value', 'pending_time (date and time, ISO 8601)'))])
      end
    end
  end

  describe 'closing with an open checklist', current_user_id: 1 do
    let(:close) { { ticket_id: ticket.id, state: 'closed' } }

    before do
      checklist = create(:checklist, ticket:, item_count: 0)
      checklist.items.create!(text: 'Call the customer back')
    end

    it 'asks whether to close anyway, as the form does, and closes on yes' do
      pending = call(arguments: close)
      request = pending.dig(:inputRequests, 'values', :params)

      expect(request[:message]).to eq("Ticket #{ticket.number}: checklist has 1 open item: Call the customer back. Close the ticket anyway?")
      expect(request[:requestedSchema]).to eq(type: 'object', properties: {})
      expect(ticket.reload.state.name).to eq('open')

      expect(call(answered(pending[:requestState], nil), arguments: close)[:isError]).to be(false)
      expect(ticket.reload.state.name).to eq('closed')
    end

    it 'closes nothing, on yes or no, once the checklist was completed meanwhile' do
      state = call(arguments: close)[:requestState]
      ticket.checklist.items.each { |item| item.update!(checked: true) }

      [answered(state, nil), answered(state, nil, action: 'decline')].each do |answer|
        expect(call(answer, arguments: close)).to include(isError: true, content: [include(text: include('confirmation_required'))])
        expect(ticket.reload.state.name).to eq('open')
      end
    end

    it 'names at most five open items, each shortened, and how many more' do
      ticket.checklist.items.create!(text: "Check the logs #{'of every server ' * 8}")
      5.times { |index| ticket.checklist.items.create!(text: "Item #{index + 2}") }

      pending = call(arguments: close)
      message = pending.dig(:inputRequests, 'values', :params, :message)
      error   = call(context(modern: false), arguments: close).dig(:content, 0, :text)

      [message, error].each do |text|
        expect(text).to include('7 open items', 'Call the customer back', 'Item 4', '… and 2 more').and(not_include('Item 5', 'Item 6'))
        expect(text).not_to include('of every server ' * 7)
      end
      expect(error.scan('<text source="agent" field="checklist_item">').size).to eq(6)
    end

    it 'names the open items when the user declines the form' do
      state = call(arguments: close)[:requestState]

      result = call(answered(state, nil, action: 'decline'), arguments: close)

      expect(result).to include(isError: true, content: [include(text: include('checklist_incomplete', '│ Call the customer back').and(not_include('close_with_open_checklist')))])
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'names the open items where the client cannot show a form, and closes once the user agreed in the conversation' do
      expect(call(context(modern: false), arguments: close)).to include(isError: true, content: [include(text: include('checklist_incomplete', '│ Call the customer back', 'call again with close_with_open_checklist: true.'))])
      expect(ticket.reload.state.name).to eq('open')

      expect(call(context(modern: false), arguments: close.merge(close_with_open_checklist: true))[:isError]).to be(false)
      expect(ticket.reload.state.name).to eq('closed')
    end

    it 'takes no close_with_open_checklist for the answer where the client shows the form' do
      with_yes = close.merge(close_with_open_checklist: true)
      state    = call(arguments: with_yes)[:requestState]

      expect(state).to be_present
      expect(call(answered(state, nil, action: 'decline'), arguments: with_yes)).to include(isError: true)
      expect(ticket.reload.state.name).to eq('open')
    end
  end
end

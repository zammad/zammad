# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'CoreWorkflow > Condition key resolution', type: :model do
  let(:agent)    { create(:agent, groups: [ticket.group]) }
  let(:customer) { create(:customer, note: 'customer note', organization: create(:organization)) }
  let(:ticket)   { create(:ticket, customer: customer) }

  def resolve(key, record:, class_name:, params: {})
    result_object = CoreWorkflow::Result.new(
      payload: { 'class_name' => class_name, 'screen' => 'edit', 'params' => { 'id' => record.id }.merge(params) },
      user:    agent,
      assets:  false,
      policy:  false,
    )
    condition = CoreWorkflow::Condition.new(result_object: result_object)
    condition.check = 'saved'
    condition.condition_key_value(key)
  end

  def matched?(condition_saved)
    workflow = create(:core_workflow, object: 'Ticket', condition_saved: condition_saved)

    result = CoreWorkflow.perform(
      payload: { 'event' => 'core_workflow', 'request_id' => 'spec', 'class_name' => 'Ticket', 'screen' => 'edit', 'params' => { 'id' => ticket.id } },
      user:    agent,
    )

    result[:matched_workflows].include?(workflow.id)
  end

  context 'with a key that names a method instead of an attribute' do
    it 'does not invoke the method and resolves to nothing' do
      expect { resolve('ticket.destroy', record: ticket, class_name: 'Ticket') }
        .not_to change { Ticket.exists?(ticket.id) }
    end

    it 'resolves ticket.destroy to an invalid key' do
      expect(resolve('ticket.destroy', record: ticket, class_name: 'Ticket')).to be_nil
    end

    it 'does not invoke the method on the session user' do
      expect { resolve('session.destroy', record: ticket, class_name: 'Ticket') }
        .not_to change { User.exists?(agent.id) }
    end

    it 'resolves session.<method> to an invalid key' do
      expect(resolve('session.new_record?', record: ticket, class_name: 'Ticket')).to be_nil
    end

    it 'resolves article.<method> to an invalid key' do
      expect(resolve('article.new_record?', record: ticket, class_name: 'Ticket', params: { 'article' => { 'body' => 'text' } })).to be_nil
    end

    it 'does not evaluate a stored condition into a match (is set)' do
      expect(matched?({ 'ticket.destroy' => { 'operator' => 'is set' } })).to be(false)
    end
  end

  context 'with a rejected key and an operator that matches an empty value' do
    before { ticket.update!(owner: agent) }

    it 'does not match with not set' do
      expect(matched?({ 'owner.login' => { 'operator' => 'not_set' } })).to be(false)
    end

    it 'does not match with is not' do
      expect(matched?({ 'owner.login' => { 'operator' => 'is not', 'value' => ['someone-else'] } })).to be(false)
    end

    it 'still matches a valid attribute that is empty with not set' do
      expect(matched?({ 'ticket.pending_time' => { 'operator' => 'not_set' } })).to be(true)
    end

    it 'still matches a missing association with not set' do
      ticket.update_columns(organization_id: nil)
      expect(matched?({ 'organization.name' => { 'operator' => 'not_set' } })).to be(true)
    end

    it 'still matches a missing article with not set' do
      expect(matched?({ 'article.body' => { 'operator' => 'not_set' } })).to be(true)
    end
  end

  context 'with a perform field that names a method instead of an attribute' do
    let(:new_ticket) { Ticket.new }

    before do
      agent
      allow(Ticket).to receive(:new).and_call_original
      allow(Ticket).to receive(:new).with(no_args).and_return(new_ticket)
      allow(new_ticket).to receive(:destroy)

      create(:core_workflow, object: 'Ticket', perform: { 'ticket.destroy' => { 'operator' => 'set_fixed_to', 'set_fixed_to' => ['x'] } })
    end

    it 'does not invoke the method when the default value is taken from a new record' do
      CoreWorkflow.perform(
        payload: { 'event' => 'core_workflow', 'request_id' => 'spec', 'class_name' => 'Ticket', 'screen' => 'create_middle', 'params' => { 'destroy' => 'y' } },
        user:    agent,
      )

      expect(new_ticket).not_to have_received(:destroy)
    end
  end

  context 'with a key pointing at a filtered attribute' do
    it 'does not expose the password hash' do
      expect(resolve('user.password', record: agent, class_name: 'User')).to be_nil
    end
  end

  context 'with a key traversing into a non-offered association' do
    it 'does not reach the token of an associated record' do
      create(:token, action: 'api', user: agent, persistent: true)
      expect(resolve('user.tokens.first.token', record: agent, class_name: 'User')).to be_nil
    end

    it 'does not reach attributes of the owner' do
      ticket.update!(owner: agent)
      expect(resolve('owner.login', record: ticket, class_name: 'Ticket')).to be_nil
    end
  end

  context 'with the offered keys' do
    it 'reads a column attribute' do
      expect(resolve('ticket.title', record: ticket, class_name: 'Ticket')).to eq([ticket.title])
    end

    it 'traverses an offered association into an attribute' do
      expect(resolve('customer.note', record: ticket, class_name: 'Ticket')).to eq([customer.note])
    end

    it 'traverses two offered associations into an attribute' do
      expect(resolve('customer.organization.name', record: ticket, class_name: 'Ticket')).to eq([customer.organization.name])
    end

    it 'reads an attribute of the article built from the params' do
      expect(resolve('article.body', record: ticket, class_name: 'Ticket', params: { 'article' => { 'body' => 'text' } })).to eq(['text'])
    end

    it 'reads an attribute of the session user' do
      expect(resolve('session.login', record: ticket, class_name: 'Ticket')).to eq([agent.login])
    end

    it 'resolves a known non-column attribute' do
      expect(resolve('session.role_ids', record: ticket, class_name: 'Ticket')).to match_array(agent.role_ids.map(&:to_s))
    end
  end
end

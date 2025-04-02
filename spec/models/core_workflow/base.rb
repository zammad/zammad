# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

shared_context 'with core workflow base' do
  let(:group)             { create(:group) }
  let(:ticket_created_at) { Time.zone.now }
  let(:ticket_title)      { SecureRandom.uuid }
  let(:ticket_customer)   { create(:customer) }
  let(:ticket)            { create(:ticket, title: ticket_title, state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 5.days.from_now, group: group, created_at: ticket_created_at, customer: ticket_customer, **additional_ticket_attributes) }
  let!(:base_payload) do
    {
      'event'      => 'core_workflow',
      'request_id' => 'default',
      'class_name' => 'Ticket',
      'screen'     => 'create_middle',
      'params'     => {},
    }
  end
  let(:additional_ticket_attributes) { {} }
  let(:payload)      { base_payload }
  let!(:action_user) { create(:agent, groups: [ticket.group]) }
  let(:result)       { CoreWorkflow.perform(payload: payload, user: action_user) }
end

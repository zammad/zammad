# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The client half of the pickup path. Which view is resolved, and for whom, is covered by
#   spec/graphql/gql/subscriptions/cti/call_pickup_spec.rb and the specs it names.
RSpec.describe 'Desktop > Caller log > Call pickup', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent)    { create(:agent, preferences: { cti: true }) }
  let(:customer) { create(:customer, firstname: 'Franz', lastname: 'Bauer', phone: '+49 30 609854180') }
  let(:call)     { { 'direction' => 'in', 'from' => '4930609854180', 'to' => '4930609811111', 'call_id' => '4711' } }

  def process(event, params = {})
    Cti::Driver::Base.new(params: call.merge('event' => event).merge(params).with_indifferent_access, config: {}).process
  end

  def pick_up_call
    process('newCall')
    process('answer', 'user_id' => agent.id)
  end

  before do
    Setting.set('cti_integration', true)
    customer

    open_desktop('/')
    wait_for_subscription_start('ctiCallPickup')
  end

  context 'when the customer has a recent ticket' do
    before { create(:ticket, customer:) }

    it 'opens the customer detail view' do
      pick_up_call

      expect(page).to have_url(%r{/desktop/users/#{customer.id}$})
      expect(main_content).to contain_text('Franz Bauer')
    end
  end

  context 'when the customer has no recent ticket' do
    it 'opens a ticket create tab carrying the customer' do
      pick_up_call

      expect(page).to have_url(%r{/desktop/tickets/create/[^?]+\?customer_id=#{customer.id}$})
      expect(selected_options('Customer')).to have_text('Franz Bauer')
    end
  end

  context 'when no customer was detected' do
    let(:agent)         { create(:agent, groups: [group, another_group], preferences: { cti: true }) }
    let(:group)         { create(:group) }
    let(:another_group) { create(:group) }
    let(:call)          { super().merge('from' => '4930609812345') }

    it 'opens a ticket create tab with the number as the customer, who is created with the ticket' do
      pick_up_call

      expect(page).to have_url(%r{/desktop/tickets/create/[^?]+\?customer_phone=})
      wait_for_form_to_settle('ticket-create')

      expect(selected_options('Customer')).to have_text('+49 30 609812345')
      expect(flyout('New user')).to have_count(0)

      fill_field('Title', 'Call from an unknown number')
      type_in_editor('Text', 'The caller asked for a quote.')
      search_for_option('Group', group.name)

      page.get_by_role('button', name: 'Create', exact: true).click

      expect(notification('Ticket has been created successfully')).to be_visible

      customer = Ticket.last.customer

      expect(customer).to have_attributes(
        phone:     '+49 30 609812345',
        firstname: '',
        lastname:  '',
        email:     '',
        role_ids:  Role.signup_role_ids,
      )

      # The next call from that number finds the customer.
      expect(Cti::CallerId.where(user_id: customer.id, caller_id: '4930609812345', level: 'known')).to exist
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Create > Signatures', time_zone: 'Europe/London', type: :system do
  describe 'No signature on new ticket if email is default message type #3844', authenticated_as: :authenticate do
    def authenticate
      Setting.set('ui_ticket_create_default_type', 'email-out')
      Group.where.not(name: 'Users').each { |g| g.update(active: false) }
      true
    end

    before do
      visit 'ticket/create'
    end

    it 'does render the create screen with an initial core workflow state to set signatures and other defaults properly' do
      expect(page.find('.richtext-content')).to have_text('Support')
    end
  end

  describe 'Zammad 5 mail template double signature #3816', authenticated_as: :authenticate do
    let(:agent_template) { create(:agent) }
    let!(:template) do
      create(
        :template,
        :dummy_data,
        group: Group.first, owner: agent_template,
        body: 'Content dummy.<br><br><div data-signature="true" data-signature-id="1">  Test Other Agent<br><br>--<br> Super Support - Waterford Business Park<br> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br> Email: hot@example.com - Web: <a href="http://www.example.com/" rel="nofollow noreferrer noopener" target="_blank">http://www.example.com/</a><br>--</div>'
      )
    end

    def authenticate
      Group.first.update(signature: Signature.first)
      true
    end

    before do
      visit 'ticket/create'
      find('[data-type=email-out]').click
    end

    it 'does not show double signature on template usage' do
      set_tree_select_value('group_id', Group.first.name)
      use_template(template)
      expect(page).to have_no_text('Test Other Agent')
    end
  end

  describe 'Setting a group via CoreWorkflow in the ticket creation mask does not update text module filters and email signatures #4891', authenticated_as: :authenticate do
    let(:group_1) { create(:group, signature: create(:signature, body: SecureRandom.uuid)) }
    let(:group_2) { create(:group, signature: create(:signature, body: SecureRandom.uuid)) }
    let(:workflow_1) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => Ticket::Priority.find_by(name: '3 high').id.to_s } },
             perform:            { 'ticket.group_id' => { 'operator' => 'select', 'select' => group_1.id.to_s } })
    end
    let(:workflow_2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => Ticket::Priority.find_by(name: '1 low').id.to_s } },
             perform:            { 'ticket.group_id' => { 'operator' => 'select', 'select' => group_2.id.to_s } })
    end

    def authenticate
      workflow_1 && workflow_2
      group_1 && group_2
      create(:agent, groups: Group.all)
    end

    it 'does change the signature when switching group via core workflow' do
      visit 'ticket/create'
      find('[data-type=email-out]').click

      page.find('[name=priority_id]').select '3 high'
      expect(page).to have_text(group_1.signature.body)

      page.find('[name=priority_id]').select '1 low'
      expect(page).to have_text(group_2.signature.body)
    end
  end
end

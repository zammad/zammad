# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Create', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent, groups: [group]) }
  let(:group) { create(:group) }

  context 'when creating a ticket from a template', db_strategy: :reset do

    # Activate ticket type field.
    before do
      ObjectManager::Attribute.get(object: 'Ticket', name: 'type').tap do |oa|
        oa.active = true
        oa.save!
      end
      ObjectManager::Attribute.migration_execute
    end

    let(:ticket_type) { create(:ticket_type) }
    let(:customer)    { create(:customer, :with_org) }
    let!(:template) do
      create(
        :template,
        :dummy_data,
        title:    'Template Ticket Title',
        body:     'Template Ticket Body',
        tags:     %w[foo bar],
        customer:,
        group:,
      ).tap do |template|
        template['options']['ticket.type'] = { 'value' => 'Problem' }
        template.save!
      end
    end

    it 'applies the template correctly' do

      skip 'Pending fix for https://github.com/zammad/coordination-desktop-view/issues/234'

      visit '/ticket/create'
      wait_for_form_updater
      wait_for_form_to_settle('ticket-create')

      click_on 'Apply Template'
      click_on template.name
      expect(page).to have_text(customer.fullname)
      wait_for_gql('shared/entities/user/graphql/queries/user.graphql')

      click_on 'Create'
      wait_for_gql('shared/entities/ticket/graphql/mutations/create.graphql')

      expect(page).to have_text('Ticket has been created successfully')

      expect(Ticket.last).to have_attributes(
        title:    'Template Ticket Title',
        customer: customer,
        type:     'Problem',
      )
      expect(Ticket.last.articles.first.body).to include('Template Ticket Body')
      expect(Tag.tag_list(object: 'Ticket', o_id: Ticket.last.id)).to eq(%w[foo bar])
    end
  end

end

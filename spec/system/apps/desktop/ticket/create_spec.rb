# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Create', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent)         { create(:agent, groups: [group, another_group]) }
  let(:group)         { create(:group) }
  let(:another_group) { create(:group) }
  let(:ticket_type)   { create(:ticket_type) }
  let(:customer)      { create(:customer, :with_org) }

  context 'when creating a ticket' do
    before do
      visit '/ticket/create'
      wait_for_form_to_settle('ticket-create')
    end

    it 'creates a new ticket' do
      find('[role="tab"]', text: 'Send Email').click

      within_form(form_updater_gql_number: 2) do
        expect(page).to have_css('h1', text: 'New Ticket')
        find_input('Title').type('Example Ticket Title')
        expect(page).to have_css('h1', text: 'Example Ticket Title')

        find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)

        find_autocomplete('CC').search_for_option(Faker::Internet.unique.email, use_action: true)

        text = find_editor('Text')
        text.type('# ').type('Heading').type(:enter, click: false)

        find('button[aria-label="Format as bold"]').click
        text.type('Bold Text ', click: false).type(:enter, click: false)
        find('button[aria-label="Format as bold"]').click

        find('button[aria-label="Format as italic"]').click
        text.type('Italic Text ', click: false).type(:enter, click: false)

        find('button[aria-label="Add bullet list"]').click
        text.type('Bullet List ', click: false).type(:enter, click: false).type(:enter, click: false)

        find('button[aria-label="Add ordered list"]').click
        text.type('Ordered List ', click: false).type(:enter, click: false).type(:enter, click: false)

        find('button[aria-label="Add link"]').click

        # Has to be adjusted as soon as we update to new link implementation
        prompt = page.driver.browser.switch_to.alert
        prompt.send_keys('https://zammad.com')
        prompt.accept

        find_treeselect('Group').search_for_option(another_group.name)

        find_select('Priority').select_option('3 high')

      end

      click_on 'Create'

      expect(page).to have_text('Ticket has been created successfully')

      expect(Ticket.last).to have_attributes(
        title:    'Example Ticket Title',
        priority: Ticket::Priority.find_by(name: '3 high'),
        group:    another_group,
        customer: customer,
      )

      expect(Ticket.last.articles.first.body).to eq('<h1>Heading</h1><p><strong>Bold Text </strong><br></p><p><em>Italic Text </em><br></p><ul><li><p>Bullet List </p></li></ul><ol><li><p>Ordered List </p></li></ol><p><a rel="nofollow noreferrer noopener" href="https://zammad.com" target="_blank">https://zammad.com</a><br></p>')
    end
  end

  context 'when creating from a template', authenticated_as: :agent, db_strategy: :reset do
    let(:template) do
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

    before do
      ObjectManager::Attribute.get(object: 'Ticket', name: 'type').tap do |oa|
        oa.active = true
        oa.save!
      end
      ObjectManager::Attribute.migration_execute
      template

      visit '/ticket/create'
      wait_for_form_to_settle('ticket-create')
    end

    it 'applies the template correctly' do
      click_on 'Apply Template'
      click_on template.name

      wait_for_form_updater(2)

      wait_for_gql('shared/entities/user/graphql/queries/user.graphql')

      expect(page).to have_text(customer.fullname)

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

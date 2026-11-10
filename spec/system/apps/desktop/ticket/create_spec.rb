# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Create', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent)         { create(:agent, groups: [group, another_group]) }
  let(:group)         { create(:group) }
  let(:another_group) { create(:group) }
  let(:ticket_type)   { create(:ticket_type) }
  let(:customer)      { create(:customer, :with_org) }

  let(:heading) { page.get_by_role('heading', level: 1) }

  def open_ticket_create
    open_desktop('/ticket/create')
    wait_for_form_to_settle('ticket-create')
  end

  context 'when creating a ticket' do
    before do
      customer
      open_ticket_create
    end

    let(:text)    { field('Text') }
    let(:toolbar) { text.get_by_role('toolbar') }

    # The body is sometimes applied to the editor once more after typing, and parsing puts
    #   the href of a link first, so the markup is compared without the attribute order.
    def without_attribute_order(html)
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css('*').each do |element|
        attributes = element.attribute_nodes.map { |attribute| [attribute.name, attribute.value] }.sort
        element.attribute_nodes.each(&:remove)
        attributes.each { |name, value| element[name] = value }
      end
      fragment.to_html
    end

    # A toolbar button takes the focus, and the editor gets it back one animation frame later.
    def click_editor_action(label)
      toolbar.get_by_role('button', name: label, exact: true).click
      expect(editor('Text')).to be_focused
    end

    it 'creates a new ticket' do
      await_form_updater('ticket-create') { page.get_by_role('tab', name: 'Send email').click }

      expect(heading).to have_text('New ticket')
      fill_field('Title', 'Example Ticket Title')
      expect(heading).to have_text('Example Ticket Title')

      search_for_option('Customer', customer.email, option: customer.fullname)

      search_for_option('CC', Faker::Internet.unique.email) do |menu|
        menu.get_by_role('button').click
      end

      type_in_editor('Text', '# ', 'Heading', :enter)

      click_editor_action('Format as bold')
      type_in_editor('Text', 'Bold Text ', :enter)
      click_editor_action('Format as bold')

      click_editor_action('Format as italic')
      type_in_editor('Text', 'Italic Text ', :enter)

      click_editor_action('Add bullet list')
      type_in_editor('Text', 'Bullet List ', :enter, :enter)

      click_editor_action('Add ordered list')
      type_in_editor('Text', 'Ordered List ', :enter, :enter)

      toolbar.get_by_role('button', name: 'Add link', exact: true).click

      link_dialog = page.get_by_role('dialog')
      fill_field('Link URL', 'https://zammad.com', within: link_dialog)
      link_dialog.get_by_role('button', name: 'Add link').click

      search_for_option('Group', another_group.name)
      select_option('Priority', '3 high')

      page.get_by_role('button', name: 'Create', exact: true).click

      expect(notification('Ticket has been created successfully')).to be_visible

      expect(Ticket.last).to have_attributes(
        title:    'Example Ticket Title',
        priority: Ticket::Priority.find_by(name: '3 high'),
        group:    another_group,
        customer: customer,
      )

      expect(without_attribute_order(Ticket.last.articles.first.body)).to start_with(without_attribute_order('<h1 dir="auto">Heading</h1><p dir="auto"><strong>Bold Text </strong></p><p dir="auto"><em>Italic Text </em></p><ul dir="auto"><li dir="auto"><p dir="auto">Bullet List </p></li></ul><ol dir="auto"><li dir="auto"><p dir="auto">Ordered List </p></li></ol><p dir="auto"><a rel="nofollow noreferrer noopener" href="https://zammad.com" target="_blank">https://zammad.com</a></p>'))
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

      open_ticket_create
    end

    it 'applies the template correctly' do
      page.get_by_role('button', name: 'Apply template').click
      await_form_updater('ticket-create') { page.get_by_role('menuitem', name: template.name).click }

      expect(main_content).to contain_text(customer.fullname)

      page.get_by_role('button', name: 'Create', exact: true).click

      expect(notification('Ticket has been created successfully')).to be_visible

      expect(Ticket.last).to have_attributes(
        title:    'Template Ticket Title',
        customer: customer,
        type:     'Problem',
      )

      expect(Ticket.last.articles.first.body).to include('Template Ticket Body')
      expect(Tag.tag_list(object: 'Ticket', o_id: Ticket.last.id)).to eq(%w[foo bar])
    end
  end

  context 'when tree select attributes have a default', db_strategy: :reset do
    before do
      create(:object_manager_attribute_tree_select, :shown_screen, display: 'Category', default: 'Incident::Hardware::Mouse')
      create(:object_manager_attribute_multi_tree_select, :shown_screen, display: 'Topics', default: ['Incident', 'Incident::Hardware::Mouse'])
      ObjectManager::Attribute.migration_execute

      open_ticket_create
    end

    it 'prefills the default values' do
      expect(field('Category').get_by_role('listitem')).to have_text([%r{^Incident › Hardware › Mouse$}])
      expect(field('Topics').get_by_role('listitem')).to have_text([%r{^Incident$}, %r{^Incident › Hardware › Mouse$}])
    end
  end

  context 'when a core workflow sets a textarea attribute read-only', db_strategy: :reset do
    before do
      create(:object_manager_attribute_textarea, :shown_screen, name: 'notes', display: 'Notes', default: "Line\n" * 20)
      ObjectManager::Attribute.migration_execute
      create(:core_workflow,
             :active_and_screen,
             object:  'Ticket',
             screen:  'create_middle',
             perform: {
               'ticket.notes': {
                 operator:     'set_readonly',
                 set_readonly: true
               },
             })

      open_ticket_create
    end

    # The disabled wrapper turns pointer events off, the textarea has to turn them back
    #   on, so its overflowing content stays scrollable and selectable (#6494).
    it 'keeps the overflowing content reachable' do
      textarea = field('Notes').get_by_role('textbox')

      expect(textarea).to have_attribute('readonly', '')
      expect(textarea).to have_css('pointer-events', 'auto')
    end
  end

  context 'when user tree select attributes have a default', db_strategy: :reset do
    before do
      screens = { create: { '-all-' => { shown: true } } }
      create(:object_manager_attribute_tree_select, object_name: 'User', screens:, display: 'Category', default: 'Incident::Hardware::Mouse')
      create(:object_manager_attribute_multi_tree_select, object_name: 'User', screens:, display: 'Topics', default: ['Incident', 'Incident::Hardware::Mouse'])
      ObjectManager::Attribute.migration_execute

      open_ticket_create
    end

    it 'prefills the default values when creating a new customer' do
      page.get_by_role('link', name: 'Create new customer').click

      user_create = flyout('Create new customer')

      expect(field('Category', within: user_create).get_by_role('listitem')).to have_text([%r{^Incident › Hardware › Mouse$}])
      expect(field('Topics', within: user_create).get_by_role('listitem')).to have_text([%r{^Incident$}, %r{^Incident › Hardware › Mouse$}])
    end
  end
end

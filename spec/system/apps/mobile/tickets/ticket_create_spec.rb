# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/core_workflow_examples'

RSpec.describe 'Mobile > Ticket > Create', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let!(:customer) { create(:customer) }

  def next_step
    find_button('Continue').click
  end

  def check_is_step(step)
    expect(find("button[order=\"#{step}\"]").disabled?).to be(true)
  end

  def go_to_step(step)
    find("button[order=\"#{step}\"]").click
  end

  def select_customer(customer)
    find('.formkit-outer', text: 'Customer').click
    find('[role=searchbox]').fill_in(with: customer.lastname)
    wait_for_gql('shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.graphql')
    click '[role="option"]', text: customer.fullname
  end

  def editor_field_set(text)
    find('[name="body"]').send_keys(text)
  end

  def submit_form
    find_button('Create ticket', match: :first).click
    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/create.graphql')
  end

  def check_is_focused(element)
    expect(page.driver.browser.switch_to.active_element).to eql(element.native)
  end

  before do
    visit '/tickets/create'
    wait_for_form_to_settle('ticket-create')
  end

  shared_examples 'creating a ticket' do |article_type:, direction: nil|
    it 'can complete all steps' do
      expect(find_button('Create ticket', match: :first, disabled: true).disabled?).to be(true)

      # Step 1.
      find_field('Title').fill_in(with: Faker::Name.name_with_middle)
      next_step

      # Step 2.
      case article_type
      when 'email'
        click 'label', text: 'Send Email'
      when 'phone'
        if direction == 'out'
          click 'label', text: 'Outbound Call'
        end
      end
      next_step

      # Step 3.
      select_customer(customer)
      find('.formkit-outer', text: 'CC') if article_type == 'email'
      next_step

      # Step 4.
      editor_field_set(Faker::Hacker.say_something_smart)

      submit_form

      find('[role=alert]', text: 'Ticket has been created successfully.')

      expect(page).to have_current_path("/mobile/tickets/#{Ticket.last.id}")
      expect(Ticket.last.create_article_type_id).to eq(Ticket::Article::Type.find_by(name: article_type).id)
    end
  end

  context 'with different article types' do
    it_behaves_like 'creating a ticket', article_type: 'phone'
    it_behaves_like 'creating a ticket', article_type: 'phone', direction: 'out'
    it_behaves_like 'creating a ticket', article_type: 'email'
  end

  context 'with entered form fields' do
    it 'remembers the data when switching between steps' do

      # Step 1.
      title = Faker::Name.name_with_middle
      find_field('Title').fill_in(with: title)
      next_step

      # Step 2.
      type = 'Outbound Call'
      click 'label', text: type
      next_step

      # Step 3.
      select_customer(customer)
      next_step

      # Step 4.
      body = Faker::Hacker.say_something_smart
      editor_field_set(body)

      # Step 1.
      go_to_step(1)
      expect(find_field('Title').value).to eq(title)

      # Step 3.
      go_to_step(3)
      expect(find('.formkit-outer', text: 'Customer')).to have_text(customer.fullname)

      # Step 2.
      go_to_step(2)
      expect(find('label', text: type)['data-is-checked']).to eq('true')

      # Step 4.
      go_to_step(4)
      expect(find('[name="body"]')).to have_text(body)
    end

    it 'shows a confirmation dialog when leaving the screen' do
      find_field('Title').fill_in(with: Faker::Name.name_with_middle)

      wait_for_gql('shared/components/Form/graphql/queries/formUpdater.graphql', number: 2)

      find('button[aria-label="Go back"]').click

      within '[role=alert]' do
        expect(page).to have_text('Are you sure? You have unsaved changes that will get lost.')
      end
    end
  end

  context 'with accessibility support' do
    it 'focuses first visible field when switching between steps' do

      # Step 1.
      check_is_focused find_field('Title')
      next_step

      # Step 2.
      check_is_focused find('label', text: 'Received Call').find('input')
      next_step

      # Step 3.
      check_is_focused find('.formkit-outer', text: 'Customer').find('output', visible: :all)
      next_step

      # Step 4.
      check_is_focused find('[name="body"]')

      # Step 1.
      go_to_step(1)
      check_is_focused find_field('Title')

      # Step 3.
      go_to_step(3)
      check_is_focused find('.formkit-outer', text: 'Customer').find('output', visible: :all)

      # Step 2.
      go_to_step(2)
      check_is_focused find('label', text: 'Received Call').find('input')

      # Step 4.
      go_to_step(4)
      check_is_focused find('[name="body"]')
    end

    it 'advances to the next step on submit' do
      find_field('Title').send_keys :enter
      check_is_step(2)

      find('label', text: 'Received Call').find('input').send_keys :enter
      check_is_step(3)
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'Ticket' }
      let(:before_it) do
        lambda {
          visit '/tickets/create'
          wait_for_form_to_settle('ticket-create')

          find_field('Title').fill_in(with: Faker::Name.name_with_middle)
          next_step
          next_step
        }
      end
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/core_workflow_examples'
require 'system/examples/text_modules_examples'

RSpec.describe 'Ticket Create', time_zone: 'Europe/London', type: :system do

  context 'when calling without session' do
    describe 'redirect to' do

      it 'login screen after certain create was called', authenticated_as: false do
        visit '#ticket/create/id/1234'

        expect(page).to have_css('#login')
      end

      it 'login screen after generic create was called', authenticated_as: false do
        visit '#ticket/create'

        expect(page).to have_css('#login')
      end
    end
  end

  context 'when logged in as non admin' do
    let(:agent) { create(:agent) }

    it 'show manage templates text only', authenticated_as: :agent do
      visit 'ticket/create'

      expect(page).to have_no_css('div.js-createLink', visible: :all)
      expect(page).to have_no_css('div.js-createTextOnly', visible: :hidden)
    end
  end

  context 'when using the sidebar' do
    context 'when using a template' do
      before do
        visit 'ticket/create'
        use_template(create(:template, :dummy_data, customer: create(:customer, :with_org)))
      end

      it 'does show the edit link for the customer' do
        click '.tabsSidebar-tab[data-tab=customer]'
        click '#userAction'
        click_on 'Edit Customer'
        modal_ready
      end

      it 'does show the edit link for the organization' do
        click '.tabsSidebar-tab[data-tab=organization]'
        click '#userAction'
        click_on 'Edit Organization'
        modal_ready
      end
    end

    %w[idoit gitlab github].each do |service_name|
      it "#{service_name} tab is hidden" do
        visit 'ticket/create'

        expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
      end

      context "when #{service_name} is enabled" do
        before do
          Setting.set("#{service_name}_integration", true)
        end

        context 'when agent' do
          it "#{service_name} tab is visible" do
            visit 'ticket/create'

            expect(page).to have_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end

        context 'when customer', authenticated_as: :customer do
          let(:customer) { create(:customer) }

          it "#{service_name} tab is hidden" do
            visit 'customer_ticket_new'

            expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end
      end
    end
  end

  context 'when logged in as admin' do
    let(:admin) { create(:admin) }

    it 'show manage templates link', authenticated_as: :admin do
      visit 'ticket/create'

      expect(page).to have_no_css('div.js-createLink', visible: :hidden)
      expect(page).to have_no_css('div.js-createTextOnly', visible: :all)
    end
  end

  context 'when applying ticket templates' do
    let(:agent)                       { create(:agent, groups: [permitted_group]) }
    let(:permitted_group)             { create(:group) }
    let(:unpermitted_group)           { create(:group) }
    let!(:template_unpermitted_group) { create(:template, :dummy_data, group: unpermitted_group, owner: agent) }
    let!(:template_permitted_group)   { create(:template, :dummy_data, group: permitted_group, owner: agent) }

    before { visit 'ticket/create' }

    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    it 'unavailable attributes do not get applied', authenticated_as: :agent do
      use_template(template_unpermitted_group)
      expect(all('[name="group_id"] option', visible: :all).map(&:value)).not_to eq unpermitted_group.id.to_s
      expect(find('[name="owner_id"]', visible: :all).value).to eq agent.id.to_s
    end

    it 'available attributes get applied', authenticated_as: :agent do
      use_template(template_permitted_group)
      expect(find('[name="group_id"]', visible: :all).value).to eq permitted_group.id.to_s
      expect(find('[name="owner_id"]', visible: :all).value).to eq agent.id.to_s
    end

    context 'with tag values' do
      let(:template) do
        create(:template,
               options: {
                 'ticket.tags': {
                   value:    template_value,
                   operator: operator,
                 }
               })
      end

      shared_examples 'merging with existing tags in a dirty form' do
        it 'merges with existing tags in a dirty form' do
          set_tokens_field_value('tags', %w[baz qux foo])
          use_template(template)
          check_tokens_field_value('tags', ['baz', 'qux', *template_value.split(', ')])
        end
      end

      shared_examples 'replacing tags in a clean form' do
        it 'replaces tags in a clean form' do
          use_template(template)
          check_tokens_field_value('tags', template_value.split(', '), visible: :all)
        end
      end

      shared_examples 'leaving tags empty in a clean form' do
        it 'does nothing in a clean form' do
          use_template(template)
          check_tokens_field_value('tags', '')
        end
      end

      context 'with add operator' do
        let(:operator) { 'add' }
        let(:template_value) { 'foo, bar' }

        it_behaves_like 'replacing tags in a clean form'
        it_behaves_like 'merging with existing tags in a dirty form'
      end

      context 'with remove operator' do
        let(:operator) { 'remove' }
        let(:template_value) { 'foo, bar' }

        it_behaves_like 'leaving tags empty in a clean form'

        it 'removes existing tags in a dirty form' do
          set_tokens_field_value('tags', %w[foo bar baz qux])
          use_template(template)
          check_tokens_field_value('tags', %w[baz qux])
        end
      end

      context 'without operator (legacy)' do
        let(:operator) { nil }
        let(:template_value) { 'foo, bar' }

        it_behaves_like 'replacing tags in a clean form'
        it_behaves_like 'merging with existing tags in a dirty form'
      end

      context 'with empty value' do
        let(:operator) { nil }
        let(:template_value) { nil }

        it_behaves_like 'leaving tags empty in a clean form'

        it 'leaves existing tags untouched in a dirty form' do
          set_tokens_field_value('tags', %w[baz qux])
          use_template(template)
          check_tokens_field_value('tags', %w[baz qux])
        end
      end
    end

  end

  context 'when using text modules' do
    include_examples 'text modules', path: 'ticket/create'
  end

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, :required_screen, name: 'maxtest', display: 'maxtest', data_option: {
               'type'      => 'text',
               'maxlength' => 3,
               'null'      => true,
               'translate' => false,
               'default'   => '',
               'options'   => {},
               'relation'  => '',
             })
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'checks ticket create' do
      visit 'ticket/create'
      within(:active_content) do
        fill_in 'maxtest', with: 'hellu'
        expect(page.find_field('maxtest').value).to eq('hel')
      end
    end
  end

  describe 'object manager attributes default date', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      screens = {
        'create_top' => {
          '-all-' => {
            'null' => true
          }
        },
      }

      create(:object_manager_attribute_date, name: 'date_test', display: 'date_test', default: 24, screens: screens)
      create(:object_manager_attribute_datetime, name: 'datetime_test', display: 'datetime_test', default: 100, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    before do
      visit '/'

      template = create(:template, :dummy_data)

      travel 1.month
      browser_travel_to Time.current

      visit 'ticket/create'
      use_template template, without_taskbar: true
    end

    let(:field_date) { find 'input[name="{date}date_test"]', visible: :all }
    let(:field_time) { find 'input[name="{datetime}datetime_test"]', visible: :all }

    it 'prefills date' do
      expect(field_date.value).to eq 1.day.from_now.to_date.to_s
    end

    it 'prefills datetime' do
      expect(Time.zone.parse(field_time.value)).to eq 100.minutes.from_now.change(sec: 0, usec: 0)
    end

    it 'saves dates' do
      click '.js-submit'

      date = 1.day.from_now.to_date
      time = 100.minutes.from_now.change(sec: 0)

      expect(Ticket.last).to have_attributes date_test: date, datetime_test: time
    end

    it 'allows to save with different values' do
      date = 2.days.from_now.to_date
      time = 200.minutes.from_now.change(sec: 0)

      field_date.sibling('[data-item=date]').set date.strftime('%m/%d/%Y')
      field_time.sibling('[data-item=date]').set time.strftime('%m/%d/%Y')
      field_time.sibling('[data-item=time]').set time.strftime('%H:%M')

      click '.js-submit'

      expect(Ticket.last).to have_attributes date_test: date, datetime_test: time
    end

    it 'allows to save with cleared value' do
      field_date.sibling('[data-item=date]').click
      find('.datepicker .clear').click
      field_time.sibling('[data-item=date]').click
      find('.datepicker .clear').click

      click '.js-submit'

      expect(Ticket.last).to have_attributes date_test: nil, datetime_test: nil
    end
  end

  describe 'GitLab Integration', :integration, authenticated_as: :authenticate, required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN] do
    let(:customer) { create(:customer) }
    let(:agent)     { create(:agent, groups: [Group.find_by(name: 'Users')]) }
    let!(:template) { create(:template, :dummy_data, group: Group.find_by(name: 'Users'), owner: agent, customer: customer) }

    def authenticate
      Setting.set('gitlab_integration', true)
      Setting.set('gitlab_config', {
                    api_token: ENV['GITLAB_APITOKEN'],
                    endpoint:  ENV['GITLAB_ENDPOINT'],
                  })
      true
    end

    it 'creates a ticket with links' do
      visit 'ticket/create'
      within(:active_content) do
        use_template(template)

        # switch to gitlab sidebar
        click('.tabsSidebar-tab[data-tab=gitlab]')
        click('.sidebar-header-headline.js-headline')

        # add issue
        click_on 'Link issue'
        fill_in 'link', with: ENV['GITLAB_ISSUE_LINK']
        click_on 'Submit'

        # verify issue
        content = find('.sidebar-git-issue-content')
        expect(content).to have_text('#1 Example issue')
        expect(content).to have_text('critical')
        expect(content).to have_text('special')
        expect(content).to have_text('important milestone')
        expect(content).to have_text('zammad-robot')

        # create Ticket
        click '.js-submit'

        # check stored data
        expect(Ticket.last.preferences[:gitlab][:issue_links][0]).to eq(ENV['GITLAB_ISSUE_LINK'])
      end
    end
  end

  describe 'GitHub Integration', :integration, authenticated_as: :authenticate, required_envs: %w[GITHUB_ENDPOINT GITHUB_APITOKEN] do
    let(:customer) { create(:customer) }
    let(:agent)     { create(:agent, groups: [Group.find_by(name: 'Users')]) }
    let!(:template) { create(:template, :dummy_data, group: Group.find_by(name: 'Users'), owner: agent, customer: customer) }

    def authenticate
      Setting.set('github_integration', true)
      Setting.set('github_config', {
                    api_token: ENV['GITHUB_APITOKEN'],
                    endpoint:  ENV['GITHUB_ENDPOINT'],
                  })
      true
    end

    it 'creates a ticket with links' do
      visit 'ticket/create'
      within(:active_content) do
        use_template(template)

        # switch to github sidebar
        click('.tabsSidebar-tab[data-tab=github]')
        click('.sidebar-header-headline.js-headline')

        # add issue
        click_on 'Link issue'
        fill_in 'link', with: ENV['GITHUB_ISSUE_LINK']
        click_on 'Submit'

        # verify issue
        content = find('.sidebar-git-issue-content')
        expect(content).to have_text('#1575 GitHub integration')
        expect(content).to have_text('enhancement')
        expect(content).to have_text('integration')
        expect(content).to have_text('4.0')
        expect(content).to have_text('Thorsten')

        # create Ticket
        click '.js-submit'

        # check stored data
        expect(Ticket.last.preferences[:github][:issue_links][0]).to eq(ENV['GITHUB_ISSUE_LINK'])
      end
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'Ticket' }
      let(:before_it) do
        lambda {
          ensure_websocket(check_if_pinged: false) do
            visit 'ticket/create'
          end
        }
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2669
  context 'when canceling new ticket creation' do
    it 'closes the dialog' do
      visit 'ticket/create'

      task_key = find(:task_active)['data-key']

      expect { click('.js-cancel') }.to change { has_selector?(:task_with, task_key, wait: 0) }.to(false)
    end

    it 'asks for confirmation if the dialog was modified' do
      visit 'ticket/create'

      task_key = find(:task_active)['data-key']

      find('[name=title]').fill_in with: 'Title'

      click '.js-cancel'

      in_modal do
        click '.js-submit'
      end

      expect(page).to have_no_selector(:task_with, task_key)
    end

    it 'asks for confirmation if attachment was added' do
      visit 'ticket/create'

      within :active_content do
        page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
        await_empty_ajax_queue
        expect(page).to have_css('.attachments .attachment-delete', visible: :all)
        find('.js-cancel').click
      end

      in_modal do
        expect(page).to have_text 'Tab has changed'
      end
    end
  end

  context 'when uploading attachment' do
    it 'shows an error if server throws an error' do
      allow(Store).to receive(:create!) { raise 'Error' }
      visit 'ticket/create'

      within :active_content do
        page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
        await_empty_ajax_queue
      end

      in_modal do
        expect(page).to have_text 'Error'
      end
    end
  end

  context 'when closing taskbar tab for new ticket creation' do
    it 'close task bar entry after some changes in ticket create form' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=title]').fill_in with: 'Title'
      end

      wait.until { find(:task_active)['data-key'].present? }

      taskbar_tab_close(find(:task_active)['data-key'])
    end
  end

  describe 'customer selection to check the field search' do
    before do
      create(:customer, active: true)
      create(:customer, active: false)
    end

    it 'check for inactive customer in customer/organization selection' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=customer_id] ~ .user-select.token-input').fill_in with: '**'
        expect(page).to have_css('ul.recipientList > li.recipientList-entry', minimum: 2)
        expect(page).to have_css('ul.recipientList > li.recipientList-entry.is-inactive', count: 1)
      end
    end
  end

  context 'when agent and customer user login after another' do
    let(:agent)    { create(:agent, password: 'test') }
    let(:customer) { create(:customer, password: 'test') }

    it 'customer user should not have agent object attributes', authenticated_as: false do

      # Create agent session and fetch object attributes.
      login(
        username: agent.login,
        password: 'test'
      )
      visit 'ticket/create'

      expect(page).to have_field('customer_id', type: 'hidden')

      # Remove local object attributes bound to the session.
      #   There was an issue (#1856) where the old attribute values
      #   persisted and were stored as the original attributes.
      logout

      # Create customer session and fetch object attributes.
      login(
        username: customer.login,
        password: 'test'
      )
      visit 'customer_ticket_new'

      expect(page).to have_no_field('customer_id', type: 'hidden')
    end
  end

  context 'when state options have a special translation', authenticated_as: :authenticate do
    let(:admin_de) { create(:admin, preferences: { locale: 'de-de' }) }

    context 'when translated state option has a single quote' do
      def authenticate
        open_tranlation = Translation.where(locale: 'de-de', source: 'open')
        open_tranlation.update(target: "off'en")

        admin_de
      end

      it 'shows the translated state options correctly' do
        visit 'ticket/create'

        expect(page).to have_select('state_id', with_options: ["off'en"])
      end
    end
  end

  describe 'It should be possible to show attributes which are configured shown false #3726', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_text, name: field_name, display: field_name, screens: {
               'create_middle' => {
                 'ticket.agent' => {
                   'shown'    => false,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
    end

    before do
      visit 'ticket/create'
    end

    context 'when field visible' do
      let(:workflow) do
        create(:core_workflow,
               object:  'Ticket',
               perform: { "ticket.#{field_name}" => { 'operator' => 'show', 'show' => 'true' } })
      end

      def authenticate
        field
        workflow
        true
      end

      it 'does show up the field' do
        expect(page).to have_css("div[data-attribute-name='#{field_name}']")
      end
    end

    context 'when field hidden' do
      def authenticate
        field
        true
      end

      it 'does not show the field' do
        expect(page).to have_css("div[data-attribute-name='#{field_name}'].is-hidden.is-removed", visible: :hidden)
      end
    end
  end

  describe 'Support workflow mechanism to do pending reminder state hide pending time use case #3790', authenticated_as: :authenticate do
    let(:template) { create(:template, :dummy_data) }

    def add_state
      Ticket::State.create_or_update(
        name:              'pending customer feedback',
        state_type:        Ticket::StateType.find_by(name: 'pending reminder'),
        ignore_escalation: true,
        created_by_id:     1,
        updated_by_id:     1,
      )
    end

    def update_screens
      attribute = ObjectManager::Attribute.get(
        object: 'Ticket',
        name:   'state_id',
      )
      attribute.data_option[:filter] = Ticket::State.where(active: true).by_category_ids(:viewable)
      attribute.screens[:create_middle]['ticket.agent'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_agent_new)
      attribute.screens[:create_middle]['ticket.customer'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_customer_new)
      attribute.screens[:edit]['ticket.agent'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_agent_edit)
      attribute.screens[:edit]['ticket.customer'][:filter] = Ticket::State.where(active: true).by_category_ids(:viewable_customer_edit)
      attribute.save!
    end

    def create_flow
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => Ticket::State.find_by(name: 'pending customer feedback').id.to_s } },
             perform:            { 'ticket.pending_time'=> { 'operator' => 'remove', 'remove' => 'true' } })
    end

    def authenticate
      add_state
      update_screens
      create_flow
      template
      true
    end

    before do
      visit 'ticket/create'
      use_template(template)
    end

    it 'does make it possible to create pending states where the pending time is optional and not visible' do
      select 'pending customer feedback', from: 'state_id'
      click '.js-submit'
      expect(current_url).to include('ticket/zoom')
      expect(Ticket.last.state_id).to eq(Ticket::State.find_by(name: 'pending customer feedback').id)
      expect(Ticket.last.pending_time).to be_nil
    end
  end

  context 'default priority', authenticated_as: :authenticate do
    let(:template)         { create(:template, :dummy_data) }
    let(:ticket_priority)  { create(:ticket_priority, default_create: true) }
    let(:another_priority) { Ticket::Priority.find(1) }
    let(:priority_field)   { find('[name=priority_id]') }

    def authenticate
      template
      ticket_priority
      true
    end

    it 'shows default priority on load' do
      visit 'ticket/create'

      expect(priority_field.value).to eq ticket_priority.id.to_s
    end

    it 'does not reset to default priority on reload' do
      visit 'ticket/create'

      taskbar_timestamp = Taskbar.last.updated_at

      priority_field.select another_priority.name

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      refresh

      expect(priority_field.reload.value).to eq another_priority.id.to_s
    end

    it 'saves default priority' do
      visit 'ticket/create'
      use_template template
      click '.js-submit'

      expect(Ticket.last).to have_attributes(priority: ticket_priority)
    end

    it 'saves different priority if overriden' do
      visit 'ticket/create'
      use_template template
      priority_field.select another_priority.name
      click '.js-submit'

      expect(Ticket.last).to have_attributes(priority: another_priority)
    end
  end

  describe 'When looking for customers, it is no longer possible to change into organizations #3815' do
    before do
      visit 'ticket/create'

      # modal reaper ;)
      sleep 3
    end

    context 'when less than 10 customers' do
      let(:organization) { Organization.first }

      it 'has no show more option' do
        find('[name=customer_id_completion]').fill_in with: 'zam'
        expect(page).to have_css("li.js-organization[data-organization-id='#{organization.id}']")
        page.find("li.js-organization[data-organization-id='#{organization.id}']").click
        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers.hidden", visible: :all)
      end
    end

    context 'when more than 10 customers', authenticated_as: :authenticate do
      def authenticate
        customers
        true
      end

      let(:organization) { create(:organization, name: 'Zammed') }
      let(:customers) do
        create_list(:customer, 50, organization: organization)
      end

      it 'does paginate through organization' do
        find('[name=customer_id_completion]').fill_in with: 'zam'
        expect(page).to have_css("li.js-organization[data-organization-id='#{organization.id}']")
        page.find("li.js-organization[data-organization-id='#{organization.id}']").click
        wait.until { page.all("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li", visible: :all).count == 12 } # 10 users + back + show more button

        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers[organization-member-limit='10']")
        scroll_into_view('li.js-showMoreMembers')
        page.find("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers").click
        wait.until { page.all("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li", visible: :all).count == 27 } # 25 users + back + show more button

        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers[organization-member-limit='25']")
        scroll_into_view('li.js-showMoreMembers')
        page.find("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers").click
        wait.until { page.all("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li", visible: :all).count == 52 } # 50 users + back + show more button

        scroll_into_view('li.js-showMoreMembers')
        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers.hidden", visible: :all)
      end
    end
  end

  describe 'Ticket create screen will loose attachments by time #3827' do
    before do
      visit 'ticket/create'
    end

    it 'does not loose attachments on rerender of the ui' do
      # upload two files
      page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      await_empty_ajax_queue
      wait.until { page.all('div.attachment-delete.js-delete', visible: :all).count == 1 }
      expect(page).to have_text('mail001.box')
      page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail002.box'))
      await_empty_ajax_queue
      wait.until { page.all('div.attachment-delete.js-delete', visible: :all).count == 2 }
      expect(page).to have_text('mail002.box')

      # remove last file
      begin
        page.evaluate_script("$('div.attachment-delete.js-delete:last').trigger('click')") # not interactable
      rescue # Lint/SuppressedException
        # because its not interactable it also
        # returns this weird exception for the jquery
        # even tho it worked fine
      end
      await_empty_ajax_queue
      wait.until { page.all('div.attachment-delete.js-delete', visible: :all).count == 1 }
      expect(page).to have_text('mail001.box')
      expect(page).to have_no_text('mail002.box')

      # simulate rerender b
      page.evaluate_script("App.Event.trigger('ui:rerender')")
      expect(page).to have_text('mail001.box')
      expect(page).to have_no_text('mail002.box')
    end
  end

  describe 'Invalid group and owner list for tickets created via customer profile #3835' do
    let(:invalid_ticket) { create(:ticket) }

    before do
      visit "#ticket/create/id/#{invalid_ticket.id}/customer/#{User.find_by(firstname: 'Nicole').id}"
    end

    it 'does show an empty list of owners' do
      wait.until { page.all('select[name=owner_id] option').count == 1 }
      expect(page.all('select[name=owner_id] option').count).to eq(1)
    end
  end

  # https://github.com/zammad/zammad/issues/3825
  describe 'CC token field' do
    before do
      visit 'ticket/create'

      find('[data-type=email-out]').click
    end

    it 'can be cleared by cutting out text' do
      add_email 'asd@example.com'
      add_email 'def@example.com'

      find('.token', text: 'def@example.com').double_click

      send_keys([magic_key, 'x'])

      find('.token').click # trigger blur

      expect(find('[name="cc"]', visible: :all).value).to eq 'asd@example.com'
    end

    def add_email(input)
      field = find_field('CC')
      field.fill_in with: input
      field.execute_script "$(this).trigger('blur')" # trigger blur

      find '.token', text: input # wait for email to tokenize
    end
  end

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

  describe 'Tree select value cannot be set to "-" (empty) with Trigger/Scheduler/Core workflow #4024', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_tree_select, :required_screen, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end
    let(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => Ticket::Priority.find_by(name: '3 high').id.to_s } },
             perform:            { "ticket.#{field_name}" => { 'operator' => 'select', 'select' => 'Incident' } })
    end
    let(:workflow2) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => Ticket::Priority.find_by(name: '2 normal').id.to_s } },
             perform:            { "ticket.#{field_name}" => { 'operator' => 'select', 'select' => '' } })
    end

    def authenticate
      field
      workflow
      workflow2
      true
    end

    before do
      visit 'ticket/create'
    end

    it 'does select the field value properly' do
      page.find('[name=priority_id]').select '3 high'
      wait.until { page.find("input[name='#{field_name}']", visible: :all).value == 'Incident' }
      page.find('[name=priority_id]').select '2 normal'
      wait.until { page.find("input[name='#{field_name}']", visible: :all).value == '' }
    end
  end

  describe 'Assign user to multiple organizations #1573' do
    let(:organization1) { create(:organization) }
    let(:organization2) { create(:organization) }
    let(:organization3) { create(:organization) }
    let(:organization4) { create(:organization) }
    let(:user1)         { create(:agent, organization: organization1, organizations: [organization2, organization3]) }
    let(:user2)         { create(:agent, organization: organization4) }
    let(:customer1)     { create(:customer, organization: organization1, organizations: [organization2, organization3]) }
    let(:customer2)     { create(:customer, organization: organization4) }

    context 'when agent', authenticated_as: :authenticate do
      def authenticate
        user1
        user2
        true
      end

      before do
        visit 'ticket/create'
      end

      it 'does not show the organization field for user 1' do
        find('[name=customer_id_completion]').fill_in with: user1.firstname
        find("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").click
        expect(page).to have_css("div[data-attribute-name='organization_id']")
      end

      it 'does show the organization field for user 2' do
        find('[name=customer_id_completion]').fill_in with: user2.firstname
        find("li.recipientList-entry.js-object[data-object-id='#{user2.id}']").click
        expect(page).to have_no_css("div[data-attribute-name='organization_id']")
      end

      it 'can create tickets for secondary organizations' do
        fill_in 'Title', with: 'test'
        find('.richtext-content').send_keys 'test'
        set_tree_select_value('group_id', Group.first.name)

        find('[name=customer_id_completion]').fill_in with: user1.firstname
        wait.until { page.all("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").present? }
        find("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").click

        find('div[data-attribute-name=organization_id] .js-input').fill_in with: user1.organizations[0].name, fill_options: { clear: :backspace }
        wait.until { page.all("div[data-attribute-name=organization_id] .js-option[data-value='#{user1.organizations[0].id}']").present? }
        page.find("div[data-attribute-name=organization_id] .js-option[data-value='#{user1.organizations[0].id}'] span").click

        click '.js-submit'
        wait.until { Ticket.last.organization_id == user1.organizations[0].id }
      end

      it 'restores saved organization selection correctly (#5347)' do
        find('[name=customer_id_completion]').fill_in with: user1.firstname
        wait.until { page.all("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").present? }
        find("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").click

        find('div[data-attribute-name=organization_id] .js-input').fill_in with: organization2.name, fill_options: { clear: :backspace }
        wait.until { page.all("div[data-attribute-name=organization_id] .js-option[data-value='#{organization2.id}']").present? }

        taskbar_timestamp = Taskbar.last.updated_at

        page.find("div[data-attribute-name=organization_id] .js-option[data-value='#{organization2.id}'] span").click

        wait.until { Taskbar.last.updated_at != taskbar_timestamp }

        refresh

        expect(find('div[data-attribute-name=organization_id] .js-input').value).to eq(organization2.name)
      end
    end

    context 'when customer' do
      before do
        visit 'customer_ticket_new'
      end

      it 'does not show the organization field for user 1', authenticated_as: :customer1 do
        expect(page).to have_css("div[data-attribute-name='organization_id']")
      end

      it 'does show the organization field for user 2', authenticated_as: :customer2 do
        expect(page).to have_no_css("div[data-attribute-name='organization_id']")
      end

      it 'can create tickets for secondary organizations', authenticated_as: :customer1 do
        fill_in 'Title', with: 'test'
        find('.richtext-content').send_keys 'test'
        set_tree_select_value('group_id', Group.first.name)
        find('div[data-attribute-name=organization_id] .js-input').fill_in with: customer1.organizations[0].name, fill_options: { clear: :backspace }
        wait.until { page.all("div[data-attribute-name=organization_id] .js-option[data-value='#{customer1.organizations[0].id}']").present? }
        page.find("div[data-attribute-name=organization_id] .js-option[data-value='#{customer1.organizations[0].id}'] span").click
        click '.js-submit'
        wait.until { Ticket.last.organization_id == customer1.organizations[0].id }
      end
    end
  end

  describe 'Wrong default values in ticket create when creating from user profile #4088' do
    let(:customer) { create(:customer) }

    before do
      visit "ticket/create/customer/#{customer.id}"
    end

    it 'does show the default state when creating a ticket from a user profile' do
      expect(page).to have_select('state_id', selected: 'open')
    end
  end

  describe 'Ticket templates do not save the owner attribute #4175' do
    let(:agent)     { create(:agent, groups: [Group.first]) }
    let!(:template) { create(:template, :dummy_data, group: Group.first, owner: agent) }

    before do
      visit 'ticket/create'

      # Wait for the initial taskbar update to finish
      taskbar_timestamp = Taskbar.last.updated_at
      wait.until { Taskbar.last.updated_at != taskbar_timestamp }
    end

    it 'does set owners properly by templates and taskbars' do
      use_template(template)
      expect(page).to have_select('owner_id', selected: agent.fullname)
      wait.until { Taskbar.last.state['owner_id'].to_i == agent.id }
      refresh
      expect(page).to have_select('owner_id', selected: agent.fullname)
    end
  end

  describe 'Ticket templates resets article body #2434' do
    let!(:template1) { create(:template, :dummy_data, title: 'template 1', body: 'body 1') }
    let!(:template2) { create(:template, :dummy_data, title: 'template 2', body: 'body 2') }

    before do
      visit 'ticket/create'
    end

    it 'preserves text input from the user' do
      taskbar_timestamp = Taskbar.last.updated_at

      set_editor_field_value('body', 'foobar')

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      use_template(template1)
      check_input_field_value('title', 'template 1')
      check_editor_field_value('body', 'foobar')
    end

    it 'allows easy switching between templates' do
      use_template(template1)
      check_input_field_value('title', 'template 1')
      check_editor_field_value('body', 'body 1')

      use_template(template2)
      check_input_field_value('title', 'template 2')
      check_editor_field_value('body', 'body 2')

      taskbar_timestamp = Taskbar.last.updated_at

      set_editor_field_value('body', 'foobar')

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      # This time body value should be left as-is
      use_template(template1)
      check_input_field_value('title', 'template 1')
      check_editor_field_value('body', 'foobar')
    end
  end

  describe 'Ticket templates are missing pending till option #4318' do

    shared_examples 'check datetime field' do

      shared_examples 'calculated datetime value' do

        it 'applies correct datetime value' do
          use_template(template, without_taskbar: true)

          check_date_field_value(field, date.strftime('%m/%d/%Y'))
          check_time_field_value(field, date.strftime('%H:%M'))
        end

      end

      context 'with static operator' do
        let(:operator)       { 'static' }
        let(:date)           { 3.days.from_now }
        let(:template_value) { date.to_datetime.to_s }

        it_behaves_like 'calculated datetime value'
      end

      context 'with relative operator' do
        let(:operator)       { 'relative' }
        let(:template_value) { value.to_s }
        let(:date) do
          # Since front-end uses a JS-specific function to add a month value to the current date,
          #   calculating the value here with Ruby code may lead to unexpected values.
          #   Therefore, we use a reimplementation of the ECMAScript function instead.
          case range
          when 'month'
            frontend_relative_month(Time.current, value)
          when 'year'
            frontend_relative_month(Time.current, 0, year: value)
          when 'minute', 'hour'
            # Javascript disregards DST switch and simply adds hours.
            # Rails Time does respect DST switch and this causes off-by-one errors around DST.
            # Time looses time zone and DST details when converted to DateTime.
            # Then DateTime#advance matches Javascript DST ignorance.
            DateTime.current.advance range.pluralize.to_sym => value
          else
            value.send(range).from_now
          end
        end

        %w[minute hour day week month year].each do |range|
          context "with #{range} range" do
            let(:range) { range }
            let(:value) do
              case range
              when 'minute' then [*(1..120)].sample
              when 'hour' then [*(1..48)].sample
              when 'day' then [*(1..31)].sample
              when 'week' then [*(1..53)].sample
              when 'month' then [*(1..12)].sample
              when 'year' then [*(1..20)].sample
              end
            end

            it_behaves_like 'calculated datetime value'
          end
        end
      end
    end

    shared_examples 'check date field' do
      let(:date)           { 5.days.from_now }
      let(:template_value) { date.to_datetime.to_s }

      it 'applies correct date value' do
        use_template(template, without_taskbar: true)

        check_date_field_value(field, date.strftime('%m/%d/%Y'))
      end
    end

    describe 'pending till support' do
      let(:field) { 'pending_time' }
      let(:template) do
        create(:template,
               options: {
                 'ticket.state_id': {
                   value: Ticket::State.find_by(name: 'pending reminder').id.to_s,
                 },
                 "ticket.#{field}": {
                   value:    template_value,
                   operator: operator,
                   range:    (range if defined? range),
                 }
               })
      end

      before do
        freeze_time
        template
        visit '/'
        browser_travel_to Time.current
        visit 'ticket/create'
      end

      include_examples 'check datetime field'
    end

    describe 'custom attribute support' do
      let(:template) do
        create(:template,
               options: {
                 "ticket.#{field}": {
                   value:    template_value,
                   operator: (operator if defined? operator),
                   range:    (range if defined? range),
                 }
               })
      end

      before :all do # rubocop:disable RSpec/BeforeAfterAll
        screens = {
          create_middle: {
            'ticket.agent' => {
              shown: true,
            },
          },
        }

        create(:object_manager_attribute_date, name: 'test_date', display: 'test_date', screens: screens)
        create(:object_manager_attribute_datetime, name: 'test_datetime', display: 'test_datetime', screens: screens)
        ObjectManager::Attribute.migration_execute # rubocop:disable Zammad/ExistsDbStrategy
      end

      after :all do # rubocop:disable RSpec/BeforeAfterAll
        ObjectManager::Attribute.where(name: %w[test_date test_datetime]).destroy_all
      end

      before do
        freeze_time
        template
        visit '/'
        browser_travel_to Time.current
        visit 'ticket/create'
      end

      context 'with date attribute' do
        let(:field) { 'test_date' }

        include_examples 'check date field'
      end

      context 'with datetime attribute' do
        let(:field) { 'test_datetime' }

        include_examples 'check datetime field'
      end
    end
  end

  describe 'Ticket templates are missing active flag #4381' do
    let!(:active_template)   { create(:template, :dummy_data, active: true) }
    let!(:inactive_template) { create(:template, :dummy_data, active: false) }

    before do
      visit 'ticket/create'
    end

    it 'filters active templates only' do
      expect(find('#form-template select[name="id"]')).to have_css('option', text: active_template.name).and(have_no_selector('option', text: inactive_template.name))
    end
  end

  describe 'CC field cannot be customized in the new ticket templates #4421', authenticated_as: :agent do
    let(:group)         { create(:group) }
    let(:agent)         { create(:agent, groups: [group]) }
    let(:customer)      { create(:customer) }
    let(:cc_recipients) { Array.new(3) { Faker::Internet.unique.email }.join(', ') }
    let!(:template) do
      create(:template,
             options: {
               'ticket.title':          {
                 value: Faker::Name.unique.name_with_middle,
               },
               'ticket.customer_id':    {
                 value:            customer.id,
                 value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>",
               },
               'ticket.group_id':       {
                 value: group.id,
               },
               'ticket.formSenderType': {
                 value: form_sender_type,
               },
               'article.cc':            {
                 value: cc_recipients,
               },
               'article.body':          {
                 value: Faker::Hacker.say_something_smart,
               },
             })
    end

    before do
      visit 'ticket/create'
    end

    context 'with email article type' do
      let(:form_sender_type) { 'email-out' }

      it 'applies configured cc value' do
        use_template(template)

        expect(page).to have_css('label', text: 'CC')

        check_input_field_value('cc', cc_recipients, visible: :all)

        click '.js-submit'

        expect(Ticket::Article.last).to have_attributes(cc: cc_recipients)
      end
    end

    context 'with phone article type' do
      let(:form_sender_type) { 'phone-out' }

      it 'ignores configured cc value' do
        use_template(template)

        expect(page).to have_no_css('label', text: 'CC')

        click '.js-submit'

        expect(Ticket::Article.last).not_to have_attributes(cc: cc_recipients)
      end
    end
  end

  describe 'Open ticket indicator coloring setting' do
    let(:elem)        { find('[data-tab="customer"]') }
    let(:customer)    { create(:customer) }
    let(:group)       { Group.first }

    before do
      Setting.set 'ui_sidebar_open_ticket_indicator_colored', state

      customer.preferences[:tickets_open] = tickets_count
      customer.save!

      visit 'ticket/create'

      field = find '[name=customer_id]', visible: :hidden

      field.execute_script "this.value = #{customer.id}"
      field.execute_script '$(this).trigger("change")'
    end

    context 'when enabled' do
      let(:state) { true }

      context 'with 1 ticket' do
        let(:tickets_count) { 1 }

        it 'highlights as warning' do
          create(:ticket, customer: customer, group: group)

          expect(elem)
            .to have_no_selector('.tabsSidebar-tab-count--danger')
            .and have_css('.tabsSidebar-tab-count--warning')
        end
      end

      context 'with 2 tickets' do
        let(:tickets_count) { 2 }

        it 'highlights as danger' do
          expect(elem)
            .to have_css('.tabsSidebar-tab-count--danger')
            .and have_no_selector('.tabsSidebar-tab-count--warning')
        end
      end
    end

    context 'when disabled' do
      let(:state) { false }

      context 'with 2 tickets' do
        let(:tickets_count) { 2 }

        it 'does not highlight' do
          expect(elem)
            .to have_no_selector('.tabsSidebar-tab-count--danger, .tabsSidebar-tab-count--warning')
        end
      end
    end
  end

  describe 'Not possible to select multiple values in a multi-tree select when a workflow with a select action is executed #4465', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:screens) do
      {
        'create_middle' => {
          'ticket.agent' => {
            'shown'    => true,
            'required' => false,
          }
        }
      }
    end

    def authenticate
      create(:object_manager_attribute_multi_tree_select, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute

      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.priority_id': {
                 operator: 'select',
                 select:   [Ticket::Priority.find_by(name: '3 high').id.to_s]
               },
             })

      true
    end

    def multi_tree_select_click(value)
      page.evaluate_script("document.querySelector(\"div[data-attribute-name='#{field_name}'] .js-optionsList li[data-value='#{value}'] .searchableSelect-option-text\").click()")
      await_empty_ajax_queue
    end

    before do
      visit 'ticket/create'
    end

    it 'does not clear the values of the multi tree select' do
      multi_tree_select_click('Incident')
      multi_tree_select_click('Service request')
      multi_tree_select_click('Change request')
      select '1 low', from: 'priority_id'
      select 'pending reminder', from: 'state_id'
      expect(page).to have_css('span.token-label', text: 'Incident')
      expect(page).to have_css('span.token-label', text: 'Service request')
      expect(page).to have_css('span.token-label', text: 'Change request')
    end
  end

  describe 'Support title and body in core workflow actions #4519', authenticated_as: :authenticate do
    let(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: { 'ticket.priority_id'=>{ 'operator' => 'is', 'value' => [Ticket::Priority.find_by(name: '2 normal').id.to_s] } },
             perform:            { 'ticket.title' => { 'operator' => %w[fill_in set_readonly], 'fill_in' => 'title 123', 'set_readonly' => true }, 'ticket.body' => { 'operator' => %w[fill_in set_readonly], 'fill_in' => '<b>text 123</b>', 'set_readonly' => true } })
    end

    context 'when agent' do
      def authenticate
        workflow
        true
      end

      before do
        visit '#ticket/create'
      end

      it 'has core workflow support for title and text' do
        expect(page).to have_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_css('div[data-attribute-name=body].is-readonly')
        expect(page.find_field('Title').value).to eq('title 123')
        expect(page.find('div[data-name=body]')['innerHTML']).to eq('<b>text 123</b>')

        # unset readonly (https://github.com/zammad/zammad/issues/4540)
        select '1 low', from: 'priority_id'
        expect(page).to have_no_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_no_css('div[data-attribute-name=body].is-readonly')

        # reset readonly
        select '2 normal', from: 'priority_id'
        expect(page).to have_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_css('div[data-attribute-name=body].is-readonly')
      end
    end

    context 'when customer' do
      def authenticate
        workflow
        create(:customer)
      end

      before do
        visit '#customer_ticket_new'
      end

      it 'has core workflow support for title and text' do
        expect(page).to have_css('div[data-attribute-name=title].is-readonly')
        expect(page).to have_css('div[data-attribute-name=body].is-readonly')
        expect(page.find_field('Title').value).to eq('title 123')
        expect(page.find('div[data-name=body]')['innerHTML']).to eq('<b>text 123</b>')
      end
    end
  end

  describe 'Date field value of a ticket template is not added into a new ticket #4864', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_date, :required_screen, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end
    let(:template) do
      create(:template, :dummy_data).tap do |template|
        template.update(options: template.options.merge("ticket.#{field_name}" => { 'operator' => 'relative', 'value' => '1', 'range' => 'day' }))
      end
    end

    def authenticate
      field
      true
    end

    before do
      visit 'ticket/create'
      use_template(template)
    end

    it 'does create a date with a relative template value' do
      click '.js-submit'
      expect(Ticket.last).to have_attributes(field_name => 1.day.from_now.to_date)
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

  describe 'CoreWorkflow "fill in empty" fires on non-empty fields during ticket creation when logged in as customer #5004' do
    let(:body_content) { SecureRandom.uuid }
    let(:workflow) do
      create(:core_workflow,
             object:  'Ticket',
             perform: { 'article.body' => { 'operator' => 'fill_in_empty', 'fill_in_empty' => body_content } })
    end

    def setup_workflows
      workflow
    end

    context 'when agent', authenticated_as: :authenticate do
      def authenticate
        setup_workflows
        true
      end

      before do
        visit '#ticket/create'
      end

      it 'does fill the body' do
        check_editor_field_value('body', body_content)
        set_editor_field_value('body', 'new_content')
        check_editor_field_value('body', 'new_content')
        page.find('[name=priority_id]').select '3 high'
        check_editor_field_value('body', 'new_content')
      end
    end

    context 'when customer', authenticated_as: :authenticate do
      def authenticate
        setup_workflows
        create(:customer)
      end

      before do
        visit 'customer_ticket_new'
      end

      it 'does fill the body' do
        check_editor_field_value('body', body_content)
        set_editor_field_value('body', 'new_content')
        check_editor_field_value('body', 'new_content')
        page.find('[name=state_id]').select 'closed'
        check_editor_field_value('body', 'new_content')
      end
    end
  end
end

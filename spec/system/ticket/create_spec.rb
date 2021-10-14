# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/core_workflow_examples'
require 'system/examples/text_modules_examples'

RSpec.describe 'Ticket Create', type: :system do
  context 'when applying ticket templates' do
    let(:agent) { create(:agent, groups: [permitted_group]) }
    let(:permitted_group) { create(:group) }
    let(:unpermitted_group) { create(:group) }
    let!(:template) { create(:template, :dummy_data, group: unpermitted_group, owner: agent) }

    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    it 'unavailable attributes do not get applied', authenticated_as: :agent do
      visit 'ticket/create'

      use_template(template)
      expect(page).to have_no_selector 'select[name="group_id"]'
    end
  end

  context 'when using text modules' do
    include_examples 'text modules', path: 'ticket/create'
  end

  context 'S/MIME', authenticated_as: :authenticate do
    def authenticate
      Setting.set('smime_integration', true)
      Setting.set('smime_config', smime_config) if defined?(smime_config)

      current_user
    end

    context 'no certificate present' do
      let!(:template)    { create(:template, :dummy_data) }
      let(:current_user) { true }

      it 'has no security selections' do
        visit 'ticket/create'

        within(:active_content) do
          use_template(template)

          expect(page).to have_no_css('div.js-securityEncrypt.btn--active')
          expect(page).to have_no_css('div.js-securitySign.btn--active')
          click '.js-submit'

          expect(page).to have_css('.ticket-article-item', count: 1)

          open_article_meta

          expect(page).to have_no_css('span', text: 'Signed')
          expect(page).to have_no_css('span', text: 'Encrypted')

          security_result = Ticket::Article.last.preferences['security']
          expect(security_result['encryption']['success']).to be nil
          expect(security_result['sign']['success']).to be nil
        end
      end
    end

    context 'private key configured' do
      let(:current_user) { agent }
      let!(:template) { create(:template, :dummy_data, group: group, owner: agent, customer: customer) }

      let(:system_email_address) { 'smime1@example.com' }
      let(:email_address) { create(:email_address, email: system_email_address) }
      let(:group) { create(:group, email_address: email_address) }
      let(:agent_groups) { [group] }
      let(:agent) { create(:agent, groups: agent_groups) }

      before do
        create(:smime_certificate, :with_private, fixture: system_email_address)
      end

      context 'recipient certificate present' do

        let(:recipient_email_address) { 'smime2@example.com' }
        let(:customer) { create(:customer, email: recipient_email_address) }

        before do
          create(:smime_certificate, fixture: recipient_email_address)
        end

        it 'plain' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            # deactivate encryption and signing
            click '.js-securityEncrypt'
            click '.js-securitySign'

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_no_css('span', text: 'Signed')
            expect(page).to have_no_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be nil
            expect(security_result['sign']['success']).to be nil
          end
        end

        it 'signed' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            # deactivate encryption
            click '.js-securityEncrypt'

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_css('span', text: 'Signed')
            expect(page).to have_no_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be nil
            expect(security_result['sign']['success']).to be true
          end
        end

        it 'encrypted' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            # deactivate signing
            click '.js-securitySign'

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_no_css('span', text: 'Signed')
            expect(page).to have_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be true
            expect(security_result['sign']['success']).to be nil
          end
        end

        it 'signed and encrypted' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_css('span', text: 'Signed')
            expect(page).to have_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be true
            expect(security_result['sign']['success']).to be true
          end
        end

        context 'Group default behavior' do

          let(:smime_config) { {} }

          shared_examples 'security defaults example' do |sign:, encrypt:|

            it "security defaults sign: #{sign}, encrypt: #{encrypt}" do
              within(:active_content) do
                encrypt_button = find('.js-securityEncrypt', wait: 5)
                sign_button    = find('.js-securitySign', wait: 5)

                active_button_class = '.btn--active'
                expect(encrypt_button.matches_css?(active_button_class, wait: 2)).to be(encrypt)
                expect(sign_button.matches_css?(active_button_class, wait: 2)).to be(sign)
              end
            end
          end

          shared_examples 'security defaults' do |sign:, encrypt:|

            before do
              visit 'ticket/create'

              within(:active_content) do
                use_template(template)
              end
            end

            include_examples 'security defaults example', sign: sign, encrypt: encrypt
          end

          shared_examples 'security defaults group change' do |sign:, encrypt:|

            before do
              visit 'ticket/create'

              within(:active_content) do
                use_template(template)

                select new_group.name, from: 'group_id'
              end
            end

            include_examples 'security defaults example', sign: sign, encrypt: encrypt
          end

          context 'not configured' do
            it_behaves_like 'security defaults', sign: true, encrypt: true
          end

          context 'configuration present' do

            let(:smime_config) do
              {
                'group_id' => group_defaults
              }
            end

            let(:group_defaults) do
              {
                'default_encryption' => {
                  group.id.to_s => default_encryption,
                },
                'default_sign'       => {
                  group.id.to_s => default_sign,
                }
              }
            end

            let(:default_sign) { true }
            let(:default_encryption) { true }

            shared_examples 'sign and encrypt variations' do |check_examples_name|

              it_behaves_like check_examples_name, sign: true, encrypt: true

              context 'no value' do
                let(:group_defaults) { {} }

                it_behaves_like check_examples_name, sign: true, encrypt: true
              end

              context 'signing disabled' do
                let(:default_sign) { false }

                it_behaves_like check_examples_name, sign: false, encrypt: true
              end

              context 'encryption disabled' do
                let(:default_encryption) { false }

                it_behaves_like check_examples_name, sign: true, encrypt: false
              end
            end

            context 'same Group' do
              it_behaves_like 'sign and encrypt variations', 'security defaults'
            end

            context 'Group change' do
              let(:new_group) { create(:group, email_address: email_address) }

              let(:agent_groups) { [group, new_group] }

              let(:group_defaults) do
                {
                  'default_encryption' => {
                    new_group.id.to_s => default_encryption,
                  },
                  'default_sign'       => {
                    new_group.id.to_s => default_sign,
                  }
                }
              end

              it_behaves_like 'sign and encrypt variations', 'security defaults group change'
            end
          end
        end
      end
    end
  end

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create :object_manager_attribute_text, name: 'maxtest', display: 'maxtest', screens: attributes_for(:required_screen), data_option: {
        'type'      => 'text',
        'maxlength' => 3,
        'null'      => true,
        'translate' => false,
        'default'   => '',
        'options'   => {},
        'relation'  => '',
      }
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

  describe 'GitLab Integration', :integration, authenticated_as: :authenticate, required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN] do
    let(:customer) { create(:customer) }
    let(:agent) { create(:agent, groups: [Group.find_by(name: 'Users')]) }
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
    let(:agent) { create(:agent, groups: [Group.find_by(name: 'Users')]) }
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
        expect(content).to have_text('feature backlog')
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
        page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
        await_empty_ajax_queue

        find('.js-cancel').click
      end

      in_modal disappears: false do
        expect(page).to have_text 'Tab has changed'
      end
    end
  end

  context 'when uploading attachment' do
    it 'shows an error if server throws an error' do
      allow(Store).to receive(:add) { raise 'Error' }
      visit 'ticket/create'

      within :active_content do
        page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      end

      in_modal disappears: false do
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
    let(:agent) { create(:agent, password: 'test') }
    let(:customer) { create(:customer, password: 'test') }

    it 'customer user should not have agent object attributes', authenticated_as: :agent do
      visit 'ticket/create'

      logout

      # Re-create agent session and fetch object attributes.
      login(
        username: agent.login,
        password: 'test'
      )
      visit 'ticket/create'

      # Re-remove local object attributes bound to the session
      # there was an issue (#1856) where the old attribute values
      # persisted and were stored as the original attributes.
      logout

      # Create customer session and fetch object attributes.
      login(
        username: customer.login,
        password: 'test'
      )

      visit 'customer_ticket_new'

      expect(page).to have_no_css('.newTicket input[name="customer_id"]')
    end
  end

  describe 'It should be possible to show attributes which are configured shown false #3726', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create :object_manager_attribute_text, name: field_name, display: field_name, screens: {
        'create_middle' => {
          'ticket.agent' => {
            'shown'    => false,
            'required' => false,
          }
        }
      }
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
        expect(page).to have_css("div[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
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
      attribute.data_option[:filter] = Ticket::State.by_category(:viewable).pluck(:id)
      attribute.screens[:create_middle]['ticket.agent'][:filter] = Ticket::State.by_category(:viewable_agent_new).pluck(:id)
      attribute.screens[:create_middle]['ticket.customer'][:filter] = Ticket::State.by_category(:viewable_customer_new).pluck(:id)
      attribute.screens[:edit]['ticket.agent'][:filter] = Ticket::State.by_category(:viewable_agent_edit).pluck(:id)
      attribute.screens[:edit]['ticket.customer'][:filter] = Ticket::State.by_category(:viewable_customer_edit).pluck(:id)
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
      expect(Ticket.last.pending_time).to be nil
    end
  end
end

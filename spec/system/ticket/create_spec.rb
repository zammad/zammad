# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

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

      expect(page).to have_css('.js-createTextOnly')
      expect(page).to have_no_css('.js-createLink')
    end
  end

  context 'when logged in as admin' do
    let(:admin) { create(:admin) }

    it 'show manage templates link', authenticated_as: :admin do
      visit 'ticket/create'

      expect(page).to have_css('.js-createLink')
      expect(page).to have_no_css('.js-createTextOnly')
    end
  end

  describe 'GitLab Integration', :integration, authenticated_as: :authenticate, required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN] do
    let(:customer)  { create(:customer) }
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

      expect(page).to have_text 'Error'
    end
  end

  context 'when closing taskbar tab for new ticket creation' do
    it 'close task bar entry after some changes in ticket create form' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=title]').fill_in with: 'Title'
      end

      task_key = nil
      wait.until do
        task_key = find(:task_active)['data-key']
        task_key.present?
      end

      taskbar_tab_close(task_key)

      expect(page).to have_no_css(".tasks .task[data-key='#{task_key}']")
    end
  end

  context 'when using the browser back button on the ticket create screen' do
    it 'returns to the previous screen without spawning another draft' do
      visit '#dashboard'

      visit '#ticket/create'

      within(:active_content) do
        find('[name=title]').fill_in with: 'Title'
      end

      wait.until { find(:task_active)['data-key'].present? }

      page.go_back

      expect(page).to have_current_path(%r{\#dashboard\z}, url: true)
      expect(page).to have_css('.tasks .task', count: 1)
    end

    # A direct load, e. g. a bookmark, leaves no previous route behind. It cannot be visited
    # as such here, because the redirect then happens while the page is still loading and the
    # browser replaces the entry on its own; only a boot that finishes later keeps it. The
    # route history it leaves behind is therefore set up explicitly.
    it 'returns to the previous page without spawning another draft on a direct entry' do
      visit '#dashboard'

      wait.until { page.evaluate_script("App.Config.get('History').length").positive? }

      page.execute_script("App.Config.set('History', [])")
      page.execute_script("window.location.hash = '#ticket/create'")

      within(:active_content) do
        find('[name=title]').fill_in with: 'Title'
      end

      wait.until { find(:task_active)['data-key'].present? }

      page.go_back

      expect(page).to have_current_path(%r{\#dashboard\z}, url: true)
      expect(page).to have_css('.tasks .task', count: 1)
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
      wait.until { page.all('div.attachment-delete.js-delete', visible: :all).one? }
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
      wait.until { page.all('div.attachment-delete.js-delete', visible: :all).one? }
      expect(page).to have_text('mail001.box')
      expect(page).to have_no_text('mail002.box')

      # simulate rerender b
      page.evaluate_script("App.Event.trigger('ui:rerender')")
      expect(page).to have_text('mail001.box')
      expect(page).to have_no_text('mail002.box')
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

    # Ported from test/browser/agent_ticket_create_cc_tokenizer_test.rb (#1990).
    it 'tokenizes an entered email address' do
      add_email 'test@example.com'

      expect(page).to have_css('span.token-label', text: 'test@example.com')
      expect(find('[name="cc"]', visible: :all).value).to eq 'test@example.com'
    end

    def add_email(input)
      field = find_field('CC')
      field.fill_in with: input
      field.execute_script "$(this).trigger('blur')" # trigger blur

      find '.token', text: input # wait for email to tokenize
    end
  end

end

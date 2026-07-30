# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/core_workflow_examples'

RSpec.describe 'Ticket zoom', type: :system do
  context 'when ticket has an attachment' do

    let(:group)           { Group.find_by(name: 'Users') }
    let(:ticket)          { create(:ticket, group: group) }
    let(:article)         { create(:ticket_article, ticket: ticket) }
    let(:attachment_name) { 'some_file.txt' }

    before do
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'some content',
             filename:    attachment_name,
             preferences: {
               'Content-Type' => 'text/plain',
             })
    end

    context 'article was already forwarded once' do
      before do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          find('a[data-type=emailForward]').click

          click('.js-reset')
          have_no_css('.js-reset')
        end
      end

      it 'adds attachments when forwarding multiple times' do

        within(:active_content) do
          find('a[data-type=emailForward]').click
        end

        within('.js-writeArea') do
          expect(page).to have_text attachment_name
        end
      end
    end
  end

  context 'when using the sidebar' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), customer: create(:customer, :with_org)) }

    before do
      Setting.set("#{service_name}_integration", true) if defined? service_name
      visit "#ticket/zoom/#{ticket.id}"
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

    %w[idoit gitlab github].each do |service_name|
      it "#{service_name} tab is hidden" do
        expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
      end

      context "when #{service_name} is enabled" do
        let(:service_name) { service_name }

        context 'when agent' do
          it "#{service_name} tab is visible" do
            expect(page).to have_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end

        context 'when customer', authenticated_as: :customer do
          let(:customer) { create(:customer) }

          it "#{service_name} tab is hidden" do
            expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end
      end
    end
  end

  context 'when ticket has a calendar attachment' do
    let(:group) { Group.find_by(name: 'Users') }
    let(:store_file_content_name) do
      Rails.root.join('spec/fixtures/files/calendar/basic.ics').read
    end
    let(:store_file_name) { 'basic.ics' }
    let(:expected_event) do
      {
        'title'       => 'Test Summary',
        'location'    => 'https://us.zoom.us/j/example?pwd=test',
        'attendees'   => ['M.bob@example.com', 'J.doe@example.com'],
        'organizer'   => 'f.sample@example.com',
        'description' => 'Test description'
      }
    end
    let(:ticket)          { create(:ticket, group: group) }
    let(:article)         { create(:ticket_article, ticket: ticket) }

    before do
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        store_file_content_name,
             filename:    store_file_name,
             preferences: {
               'Content-Type' => 'text/calendar',
             })

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'has an attached calendar file' do
      within :active_ticket_article, article do
        within '.attachment.file-calendar' do
          expect(page).to have_text(store_file_name)
        end
      end
    end

    it 'shows a preview button for the calendar file' do
      within :active_ticket_article, article do
        within '.attachment.file-calendar' do
          expect(page).to have_button('Preview')
        end
      end
    end

    context 'when calendar preview button is clicked' do
      before do
        within :active_ticket_article, article do
          within '.attachment.file-calendar' do
            click_on 'Preview'
          end
        end
      end

      it 'shows calender data in the model' do
        in_modal do
          expect(page).to have_text expected_event['title']
          expect(page).to have_text expected_event['location']
          expected_event['attendees'].each { |attendee| expect(page).to have_text attendee }
          expect(page).to have_text expected_event['organizer']
          expect(page).to have_text expected_event['description']
        end
        click '.js-cancel'
      end
    end
  end

  # https://github.com/zammad/zammad/issues/3335
  context 'ticket state sort order maintained when locale is de-de', authenticated_as: :user do
    context 'when existing ticket is open' do
      let(:user)   { create(:customer, preferences: { locale: 'de-de' }) }
      let(:ticket) { create(:ticket, customer: user) }

      it 'shows ticket state dropdown options in sorted translated alphabetically order' do
        visit "ticket/zoom/#{ticket.id}"

        within :active_content, '.tabsSidebar' do
          expect(all('select[name=state_id] option').map(&:text)).to eq(%w[geschlossen neu offen])
        end
      end
    end

    context 'when a new ticket is created' do
      let(:user) { create(:agent, preferences: { locale: 'de-de' }, groups: [permitted_group]) }
      let(:permitted_group) { create(:group) }

      it 'shows ticket state dropdown options in sorted order' do
        visit 'ticket/create'

        expect(all('select[name=state_id] option').map(&:text)).to eq ['-', 'geschlossen', 'neu', 'offen', 'warten auf Erinnerung', 'warten auf Schließen']
      end
    end
  end

  describe 'customer draft', authenticated_as: :authenticate do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer: customer) }
    let(:article)  { create(:ticket_article, ticket: ticket) }

    def authenticate
      article
      customer
    end

    it 'restores autosaved body and keeps a supported article type (#5767)' do
      visit "ticket/zoom/#{ticket.id}"

      taskbar_timestamp = Taskbar.last.updated_at

      find(:richtext).send_keys('This is a draft body from customer')

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      refresh

      within '.article-new' do
        type_input = find('input[name="type"]', visible: false)

        expect(type_input.value).to eq('note')
        expect(page).to have_no_field('input[name=to]', visible: :visible)
        expect(find('[data-name=body]')).to have_text('This is a draft body from customer')
      end
    end
  end

  # https://github.com/zammad/zammad/issues/3260
  describe 'next in overview macro changes URL', authenticated_as: :authenticate do
    let(:next_ticket) { create(:ticket, title: 'next Ticket', group: Group.first) }
    let(:macro)       { create(:macro, name: 'next macro', ux_flow_next_up: 'next_from_overview') }

    def authenticate
      next_ticket && macro

      true
    end

    it 'to next Ticket ID' do
      visit 'ticket/view/all_unassigned'
      click_on 'Help me! I am an example ticket 🎓'
      click '.js-openDropdownMacro'
      find(:macro, macro.id).click
      wait(5, interval: 1).until_constant { current_url }

      expect(current_url).to include("ticket/zoom/#{next_ticket.id}")
    end
  end

  # https://github.com/zammad/zammad/issues/3279
  describe 'previous/next clickability when at last or first ticket' do
    let(:ticket_a)          { create(:ticket, title: 'ticket a', group: Group.first) }
    let(:ticket_b)          { create(:ticket, title: 'ticket b', group: Group.first) }

    before do
      ticket_a && ticket_b

      visit 'ticket/view/all_unassigned'
    end

    it 'previous is not clickable for the first item' do
      open_nth_item(0)

      expect(page).to have_css('.pagination .btn--split--first.is-disabled')
    end

    it 'next is clickable for the first item' do
      open_nth_item(0)

      expect { click '.pagination .btn--split--last' }.to change { page.find('.content.active')[:id] }
    end

    it 'previous is clickable for the middle item' do
      open_nth_item(1)

      expect { click '.pagination .btn--split--first' }.to change { page.find('.content.active')[:id] }
    end

    it 'next is clickable for the middle item' do
      open_nth_item(1)

      expect { click '.pagination .btn--split--last' }.to change { page.find('.content.active')[:id] }
    end

    it 'previous is clickable for the last item' do
      open_nth_item(2)

      expect { click '.pagination .btn--split--first' }.to change { page.find('.content.active')[:id] }
    end

    it 'next is not clickable for the last item' do
      open_nth_item(2)

      expect(page).to have_css('.pagination .btn--split--last.is-disabled')
    end

    def open_nth_item(nth)
      within :active_content do
        find_all('.table tr.item a[href^="#ticket/zoom"]')[nth].click
      end

      await_empty_ajax_queue
    end
  end

  # https://github.com/zammad/zammad/issues/3267
  describe 'previous/next buttons are added when open ticket is opened from overview' do
    let(:ticket_a)          { create(:ticket, title: 'ticket a', group: Group.first) }
    let(:ticket_b)          { create(:ticket, title: 'ticket b', group: Group.first) }

    # prepare an opened ticket and go to overview
    before do
      ticket_a && ticket_b

      visit "ticket/zoom/#{ticket_a.id}"

      visit 'ticket/view/all_unassigned'
    end

    it 'adds previous/next buttons to existing ticket' do
      within :active_content do
        click_on ticket_a.title

        expect(page).to have_css('.pagination-counter')
      end
    end

    it 'keeps previous/next buttons when navigating to overview ticket from elsewhere' do
      within :active_content do
        click_on ticket_a.title
        visit 'dashboard'
        visit "ticket/zoom/#{ticket_a.id}"

        expect(page).to have_css('.pagination-counter')
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2942
  describe 'attachments are lost in specific conditions' do
    let(:ticket) { create(:ticket, group: Group.first) }

    it 'attachment is retained when forwarding a fresh article' do
      ensure_websocket do
        visit "ticket/zoom/#{ticket.id}"
      end

      # add an article, forcing reset of form_id

      # click in the upper most upper left corner of the article create textbox
      # (that works for both Firefox and Chrome)
      # to avoid clicking on attachment upload
      find('.js-writeArea').click(x: 5, y: 5)

      # wait for propagateOpenTextarea to be completed
      find('.attachmentPlaceholder-label').in_fixed_position
      expect(page).to have_no_css('.attachmentPlaceholder-hint')

      # write article content
      find('.articleNewEdit-body').send_keys('Some reply')
      click '.js-submit'

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 1)

      # create a on-the-fly article with attachment that will get pushed to open browser
      article1 = create(:ticket_article, ticket: ticket)
      create(:store,
             object:      'Ticket::Article',
             o_id:        article1.id,
             data:        'some content',
             filename:    'some_file.txt',
             preferences: {
               'Content-Type' => 'text/plain',
             })

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 2)

      # click on forward of created article
      within :active_ticket_article, article1 do
        find('a[data-type=emailForward]').click
      end

      # wait for propagateOpenTextarea to be completed
      find('.attachmentPlaceholder-label').in_fixed_position
      expect(page).to have_no_css('.attachmentPlaceholder-hint')

      # fill forward information and create article
      fill_in 'To', with: 'forward@example.org'
      find('.articleNewEdit-body').send_keys('Forwarding with the attachment')
      click '.js-submit'

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 3)

      # check if attachment was forwarded successfully
      within :active_ticket_article, ticket.reload.articles.last do
        within '.attachments--list' do
          expect(page).to have_text('some_file.txt')
        end
      end
    end
  end

  describe 'mentions' do
    context 'when logged in as agent' do
      let(:ticket)        { create(:ticket, group: Group.find_by(name: 'Users')) }
      let!(:other_agent)  { create(:agent, groups: [Group.find_by(name: 'Users')]) }
      let!(:admin)        { User.find_by(email: 'admin@example.com') }

      before do
        create(:macro, name: 'Subscribe', ux_flow_next_up: 'none', perform: { 'ticket.subscribe': { value: 'current_user.id' } })
        create(:macro, name: 'Unsubscribe', ux_flow_next_up: 'none', perform: { 'ticket.unsubscribe': { value: 'current_user.id' } })
      end

      it 'can subscribe and unsubscribe' do
        # The avatar list only updates via server push - make sure the websocket
        #   session is registered before subscribing, otherwise the push (and with
        #   it the avatar) is lost for good.
        ensure_websocket do
          visit "ticket/zoom/#{ticket.id}"
        end

        # subscribe via sidebar
        click '.js-subscriptions .js-subscribe input'
        expect(page).to have_css('.js-subscriptions .js-unsubscribe input')
        expect(page).to have_css('.js-subscriptions span.avatar')

        # unsubscribe via sidebar
        click '.js-subscriptions .js-unsubscribe input'
        expect(page).to have_css('.js-subscriptions .js-subscribe input')
        expect(page).to have_no_selector('.js-subscriptions span.avatar')

        # subscribe via macro
        click '.js-openDropdownMacro'
        find(:macro, 2).click # Subscribe macro button
        expect(page).to have_css('.js-subscriptions span.avatar')

        # unsubscribe via macro
        click '.js-openDropdownMacro'
        find(:macro, 3).click # Unsubscribe macro button

        expect(page).to have_no_selector('.js-subscriptions span.avatar')

        create(:mention, mentionable: ticket, user: other_agent)
        expect(page).to have_css('.js-subscriptions span.avatar')

        # check history for mention entries
        click 'h2.sidebar-header-headline.js-headline'
        click 'li[data-type=ticket-history] a'
        expect(page).to have_text("created Mention → '#{admin.firstname} #{admin.lastname}'")
        expect(page).to have_text("removed Mention → '#{admin.firstname} #{admin.lastname}'")
        expect(page).to have_text("created Mention → '#{other_agent.firstname} #{other_agent.lastname}'")
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2671
  describe 'Pending time field in ticket sidebar', authenticated_as: :customer do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer: customer, pending_time: 1.day.from_now, state: Ticket::State.lookup(name: 'pending reminder')) }

    it 'not shown to customer' do
      visit "ticket/zoom/#{ticket.id}"

      within :active_content do
        expect(page).to have_no_css('.controls[data-name=pending_time]')
      end
    end
  end

  describe 'Pending time field in ticket sidebar as agent' do
    before do
      ticket.update(pending_time: 1.day.from_now, state: Ticket::State.lookup(name: 'pending reminder'))

      visit "ticket/zoom/#{ticket.id}"
    end

    let(:ticket) { Ticket.first }

    # has to run asynchronously to keep both Firefox and Safari
    # https://github.com/zammad/zammad/issues/3414
    # https://github.com/zammad/zammad/issues/2887
    context 'when clicking timepicker component' do
      it 'in the first half, hours selected' do
        within :active_content do
          # timepicker messes with the dom, so don't cache the element and wait a bit.
          sleep 1
          find('.js-timepicker').click(x: -10, y: 20)
          sleep 0.5
          expect(find('.js-timepicker')).to have_selection(0..2)
        end
      end

      it 'in the second half, minutes selected' do
        within :active_content do
          sleep 1
          find('.js-timepicker').click(x: 10, y: 20)
          sleep 0.5
          expect(find('.js-timepicker')).to have_selection(3..5)
        end
      end
    end

    matcher :have_selection do
      match { starts_at == expected.begin && ends_at == expected.end }

      def starts_at
        actual.evaluate_script 'this.selectionStart'
      end

      def ends_at
        actual.evaluate_script 'this.selectionEnd'
      end
    end
  end

  describe 'Macros', authenticated_as: :authenticate do
    let(:macro_body) { 'macro <b>body</b>' }
    let(:macro)      { create(:macro, perform: { 'article.note' => { 'body' => macro_body, 'internal' => 'true', 'subject' => 'macro note' } }) }
    let!(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      macro
      true
    end

    it 'does html macro by default' do
      visit "ticket/zoom/#{ticket.id}"
      find('.js-openDropdownMacro').click
      find(:macro, macro.id).click

      expect(ticket.reload.articles.last.body).to eq(macro_body)
      expect(ticket.reload.articles.last.content_type).to eq('text/html')
    end
  end

  describe 'GitLab Integration', :integration, authenticated_as: :authenticate, required_envs: %w[GITLAB_ENDPOINT GITLAB_APITOKEN] do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      Setting.set('gitlab_integration', true)
      Setting.set('gitlab_config', {
                    api_token: ENV['GITLAB_APITOKEN'],
                    endpoint:  ENV['GITLAB_ENDPOINT'],
                  })
      true
    end

    it 'creates links and removes them' do
      visit "#ticket/zoom/#{ticket.id}"
      within(:active_content) do

        # switch to GitLab sidebar
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

        expect(ticket.reload.preferences[:gitlab][:issue_links][0]).to eq(ENV['GITLAB_ISSUE_LINK'])

        # check sidebar counter increased to 1
        expect(find('.tabsSidebar-tab[data-tab=gitlab] .js-tabCounter')).to have_text('1')

        # delete issue
        click(".sidebar-git-issue-delete span[data-issue-id='#{ENV['GITLAB_ISSUE_LINK']}']")

        content = find('.sidebar[data-tab=gitlab] .sidebar-content')
        expect(content).to have_text('No linked issues')
        expect(ticket.reload.preferences[:gitlab][:issue_links][0]).to be_nil

        # check that counter got removed
        expect(page).to have_no_selector('.tabsSidebar-tab[data-tab=gitlab] .js-tabCounter')
      end
    end
  end

  describe 'GitHub Integration', :integration, authenticated_as: :authenticate, required_envs: %w[GITHUB_ENDPOINT GITHUB_APITOKEN] do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      Setting.set('github_integration', true)
      Setting.set('github_config', {
                    api_token: ENV['GITHUB_APITOKEN'],
                    endpoint:  ENV['GITHUB_ENDPOINT'],
                  })
      true
    end

    it 'creates links and removes them' do
      visit "#ticket/zoom/#{ticket.id}"
      within(:active_content) do

        # switch to GitHub sidebar
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

        expect(ticket.reload.preferences[:github][:issue_links][0]).to eq(ENV['GITHUB_ISSUE_LINK'])

        # check sidebar counter increased to 1
        expect(find('.tabsSidebar-tab[data-tab=github] .js-tabCounter')).to have_text('1')

        # delete issue
        click(".sidebar-git-issue-delete span[data-issue-id='#{ENV['GITHUB_ISSUE_LINK']}']")

        content = find('.sidebar[data-tab=github] .sidebar-content')
        expect(content).to have_text('No linked issues')
        expect(ticket.reload.preferences[:github][:issue_links][0]).to be_nil

        # check that counter got removed
        expect(page).to have_no_selector('.tabsSidebar-tab[data-tab=github] .js-tabCounter')
      end
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:object_name) { 'Ticket' }
      let(:before_it) do
        lambda {
          ensure_websocket(check_if_pinged: false) do
            visit "#ticket/zoom/#{ticket.id}"
          end
        }
      end
    end
  end

  context 'Sidebar - Open & Closed Tickets', performs_jobs: true, searchindex: true do
    let(:customer)      { create(:customer, :with_org) }
    let(:ticket_open)   { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer, title: SecureRandom.uuid) }
    let(:ticket_closed) { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer, state: Ticket::State.find_by(name: 'closed'), title: SecureRandom.uuid) }

    before do
      ticket_open
      ticket_closed
      perform_enqueued_jobs
      searchindex_model_reload([Ticket, User, Organization])
    end

    it 'does show open and closed tickets in advanced search url' do
      visit "#ticket/zoom/#{ticket_open.id}"
      click '.tabsSidebar-tab[data-tab=customer]'
      click '.user-tickets[data-type=open]'
      expect(page).to have_text(ticket_open.title)

      visit "#ticket/zoom/#{ticket_open.id}"
      click '.user-tickets[data-type=closed]'
      expect(page).to have_text(ticket_closed.title)
    end
  end

  context 'Sidebar - Organization' do
    let(:organization) { create(:organization) }

    context 'members section' do

      let(:customers) { create_list(:customer, 50, organization: organization) }
      let(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users'), customer: customers.first) }
      let(:members)   { organization.members.reorder(id: :asc) }

      before do
        visit "#ticket/zoom/#{ticket.id}"
        click '.tabsSidebar-tab[data-tab=organization]'
      end

      it 'shows first 10 members and loads more on demand' do
        expect(page).to have_text(members[9].fullname)
        expect(page).to have_no_text(members[10].fullname)

        click '.js-showMoreMembers'
        expect(page).to have_text(members[10].fullname)
      end
    end
  end

  describe 'Core Workflow: Show hidden attributes on group selection (ticket edit) #3739', authenticated_as: :authenticate, db_strategy: :reset do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_text, name: field_name, display: field_name, screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => false,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
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

  describe 'Notes on existing ticks are discarded by editing profile settings #3088' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    def upload_and_set_text
      page.find('.js-textarea').send_keys("Hello\nThis\nis\nimportant!\nyo\nhoho\ntest test test test")
      page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      expect(page).to have_text('mail001.box')
      wait_for_upload_present
    end

    def wait_for_upload_present
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].present? }
    end

    def wait_for_upload_blank
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].blank? }
    end

    def switch_language_german
      visit '#profile/language'
      # Suppress the modal dialog that invites to contributions for translations that are < 90% as this breaks the tests for de-de.
      page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"
      page.find('.js-input').click
      page.find('.js-input').set('Deutsch')
      page.find('.js-input').send_keys(:enter)
      click_on 'Submit'

      visit "#ticket/zoom/#{ticket.id}"
      expect(page).to have_text(Translation.translate('de-de', 'select attachment…'))
    end

    def expect_upload_and_text
      expect(page.find('.article-new')).to have_text('mail001.box')
      expect(page.find('.article-new')).to have_text("Hello\nThis\nis\nimportant!\nyo\nhoho\ntest test test test")
    end

    def expect_no_upload_and_text
      expect(page.find('.article-new')).to have_no_text('mail001.box')
      expect(page.find('.article-new')).to have_no_text("Hello\nThis\nis\nimportant!\nyo\nhoho\ntest test test test")
    end

    it 'does show up the attachments after a reload of the page' do
      upload_and_set_text
      expect_upload_and_text
      refresh
      expect_upload_and_text
    end

    it 'does show up the attachments after updating language (ui:rerender event)' do
      upload_and_set_text
      expect_upload_and_text
      switch_language_german
      expect_upload_and_text
    end

    it 'does remove attachments and text on reset' do
      upload_and_set_text
      expect_upload_and_text

      page.find('.js-reset').click
      wait_for_upload_blank
      expect_no_upload_and_text
      refresh
      expect_no_upload_and_text
    end

    context 'when rerendering (#3831)' do
      def rerender
        page.evaluate_script("App.Event.trigger('ui:rerender')")
      end

      it 'does loose attachments after rerender' do
        upload_and_set_text
        expect_upload_and_text
        rerender
        expect_upload_and_text
      end

      it 'does not readd the attachments after reset' do
        upload_and_set_text
        expect_upload_and_text

        page.find('.js-reset').click
        wait_for_upload_blank
        expect_no_upload_and_text
        rerender
        expect_no_upload_and_text
      end

      it 'does not readd the attachments after submit' do
        upload_and_set_text
        expect_upload_and_text

        page.find('.js-submit').click
        wait_for_upload_blank
        expect_no_upload_and_text
        rerender
        expect_no_upload_and_text
      end

      it 'does not show the ticket as changed after the upload removal' do
        page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
        await_empty_ajax_queue
        expect(page.find('.article-new')).to have_text('mail001.box')
        wait_for_upload_present
        begin
          page.evaluate_script("$('div.attachment-delete.js-delete:last').trigger('click')") # not interactable
        rescue # Lint/SuppressedException
          # because its not interactable it also
          # returns this weird exception for the jquery
          # even tho it worked fine
        end
        expect(page).to have_no_selector('.js-reset')
      end
    end
  end

  describe 'Unable to close tickets in certran cases if core workflow is used #3710', authenticated_as: :authenticate, db_strategy: :reset do
    let!(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_text, name: field_name, display: field_name, screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => false,
                   'required' => false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
    end
    let(:workflow) do
      create(:core_workflow,
             object:  'Ticket',
             perform: { "ticket.#{field_name}" => { 'operator' => 'set_mandatory', 'set_mandatory' => 'true' } })
    end

    def authenticate
      field
      workflow
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does save the ticket because the field is mandatory but hidden' do
      admin = User.find_by(email: 'admin@example.com')
      select admin.fullname, from: 'Owner'
      find('.js-submit').click
      expect(ticket.reload.owner_id).to eq(admin.id)
    end
  end

  describe "escaped 'Set fixed' workflows don't refresh set values on active ticket sessions #3757", authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), field_name => false) }

    def authenticate
      workflow
      create(:object_manager_attribute_boolean, :required_screen, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    context 'when operator set_fixed_to' do
      let(:workflow) do
        create(:core_workflow,
               object:  'Ticket',
               perform: { "ticket.#{field_name}" => { 'operator' => 'set_fixed_to', 'set_fixed_to' => ['false'] } })
      end

      context 'when saved value is removed by set_fixed_to operator' do
        it 'does show up the saved value if it would not be possible because of the restriction' do
          expect(page.find("select[name='#{field_name}']").value).to eq('false')
          ticket.update(field_name => true)
          wait.until { page.find("select[name='#{field_name}']").value == 'true' }
          expect(page.find("select[name='#{field_name}']").value).to eq('true')
        end
      end
    end

    context 'when operator remove_option' do
      let(:workflow) do
        create(:core_workflow,
               object:  'Ticket',
               perform: { "ticket.#{field_name}" => { 'operator' => 'remove_option', 'remove_option' => ['true'] } })
      end

      context 'when saved value is removed by set_fixed_to operator' do
        it 'does show up the saved value if it would not be possible because of the restriction' do
          expect(page.find("select[name='#{field_name}']").value).to eq('false')
          ticket.update(field_name => true)
          wait.until { page.find("select[name='#{field_name}']").value == 'true' }
          expect(page.find("select[name='#{field_name}']").value).to eq('true')
        end
      end
    end
  end

  context 'Basic sidebar handling because of regressions in #3757' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
      ensure_websocket
    end

    it 'does show up the new priority' do
      high_prio = Ticket::Priority.find_by(name: '3 high')
      ticket.update(priority: high_prio)
      wait.until { page.find("select[name='priority_id']").value == high_prio.id.to_s }
      expect(page.find("select[name='priority_id']").value).to eq(high_prio.id.to_s)
    end

    it 'does show up the new group (different case because it will also trigger a full rerender because of potential permission changes)' do
      group = Group.find_by(name: 'some group1')
      ticket.update(group: group)
      wait.until { page.find("input[name='group_id']", visible: :all).value == group.id.to_s }
      expect(page.find("input[name='group_id']", visible: :all).value).to eq(group.id.to_s)
    end

    it 'does show up the new state and pending time' do
      pending_state = Ticket::State.find_by(name: 'pending reminder')
      ticket.update(state: pending_state, pending_time: 1.day.from_now)

      wait(30).until { page.find("select[name='state_id']").value == pending_state.id.to_s }
      expect(page.find("select[name='state_id']").value).to eq(pending_state.id.to_s)
      expect(page).to have_css("div[data-name='pending_time']")
    end

    it 'does merge attributes with remote priority (ajax) and local state (user)' do
      select 'closed', from: 'State'
      high_prio = Ticket::Priority.find_by(name: '3 high')
      closed_state = Ticket::State.find_by(name: 'closed')
      ticket.update(priority: high_prio)
      wait.until { page.find("select[name='priority_id']").value == high_prio.id.to_s }
      expect(page.find("select[name='priority_id']").value).to eq(high_prio.id.to_s)
      expect(page.find("select[name='state_id']").value).to eq(closed_state.id.to_s)
    end

    context 'when 2 users are in 2 different tickets' do
      let(:ticket2) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:agent2)  { create(:agent, password: 'test', groups: [Group.find_by(name: 'Users')]) }

      before do
        using_session(:second_browser) do
          login(
            username: agent2.login,
            password: 'test',
          )
          visit "#ticket/zoom/#{ticket.id}"
          visit "#ticket/zoom/#{ticket2.id}"
        end
      end

      it 'does not make any changes to the second browser ticket' do
        closed_state = Ticket::State.find_by(name: 'closed')
        select 'closed', from: 'State'
        find('.js-submit').click
        using_session(:second_browser) do
          sleep 3
          expect(page.find("select[name='state_id']").value).not_to eq(closed_state.id.to_s)
        end
      end
    end
  end

  context 'Owner should get cleared if not listed in changed group #3818', authenticated_as: :authenticate do
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:agent1) { create(:agent) }
    let(:agent2) { create(:agent) }
    let(:ticket) { create(:ticket, group: group1, owner: agent1) }

    def authenticate
      agent1.group_names_access_map = {
        group1.name => 'full',
        group2.name => %w[read change overview]
      }
      agent2.group_names_access_map = {
        group1.name => 'full',
        group2.name => 'full',
      }
      agent1
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does clear agent1 on select of group 2' do
      set_tree_select_value('group_id', group2.name)
      wait.until { page.find('select[name=owner_id]').value != agent1.id.to_s }
      expect(page.find('select[name=owner_id]').value).to eq('')
      expect(page.all('select[name=owner_id] option').map(&:value)).not_to include(agent1.id.to_s)
      expect(page.all('select[name=owner_id] option').map(&:value)).to include(agent2.id.to_s)
    end
  end

  describe 'Not displayed fields should not impact the edit screen #3819', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      create(:object_manager_attribute_boolean, default: nil, screens: {
               edit: {
                 'ticket.agent' => {
                   shown:    false,
                   required: false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does not show any changes for the field because it has no value and because it is not shown it should also not show the ticket as changed' do
      sleep 3
      expect(page).to have_no_selector('.js-reset')
    end
  end

  describe 'Changing ticket status from "new" to any other status always results in uncommited status "closed" #3880', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:workflow) do
      create(:core_workflow,
             object:             'Ticket',
             condition_selected: {
               'ticket.priority_id': {
                 operator: 'is',
                 value:    [ Ticket::Priority.find_by(name: '3 high').id.to_s ],
               },
             },
             perform:            { 'ticket.state_id' => { operator: 'remove_option', remove_option: [ Ticket::State.find_by(name: 'pending reminder').id.to_s ] } })
    end

    def authenticate
      workflow
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does switch back to the saved value in the ticket instead of the first value of the dropdown' do
      page.select 'pending reminder', from: 'state_id'
      page.select '3 high', from: 'priority_id'
      expect(page).to have_select('state_id', selected: 'new')
    end
  end

  describe 'Changing ticket status resets state to the first dropdown option when the cached object is stale #3880', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      ticket
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'keeps the real ticket state instead of resetting to the first option' do
      expect(page).to have_select('state_id', selected: 'new')

      # Simulate a concurrent update whose websocket push has not yet reached
      # the client (e.g. behind a reverse proxy), so the cached ticket object
      # stays stale while the backend already sees the new state.
      Ticket.where(id: ticket.id).update_all(state_id: Ticket::State.find_by(name: 'open').id, updated_at: Time.current)

      # Trigger a Core Workflow run without touching the state field.
      page.select '3 high', from: 'priority_id'

      expect(page).to have_select('state_id', selected: 'open')
    end
  end

  describe 'Show which escalation type escalated in ticket zoom #3928', authenticated_as: :authenticate do
    let(:sla) { create(:sla, first_response_time: 1, update_time: 1, solution_time: 1) }
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      sla
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does show the extended escalation information' do
      page.find('.escalation-popover').hover
      expect(page).to have_text('FIRST RESPONSE TIME')
      expect(page).to have_text('UPDATE TIME')
      expect(page).to have_text('SOLUTION TIME')
    end
  end

  context 'Make sidebar attachments unique #3930', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:article1)         { create(:ticket_article, ticket: ticket) }
    let(:article2)         { create(:ticket_article, ticket: ticket) }

    def attachment_add(article, filename)
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        "content #{filename}",
             filename:    filename,
             preferences: {
               'Content-Type' => 'text/plain',
             })
    end

    def authenticate
      attachment_add(article1, 'some_file.txt')
      attachment_add(article2, 'some_file.txt')
      attachment_add(article2, 'some_file2.txt')
      Setting.set('ui_ticket_zoom_sidebar_article_attachments', true)

      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
      page.find(".tabsSidebar-tabs .tabsSidebar-tab[data-tab='attachment']").click
    end

    it 'does show the attachment once' do
      expect(page).to have_css('.sidebar-content .attachment.attachment--preview', count: 2)
      expect(page).to have_css('.sidebar-content', text: 'some_file.txt')
      expect(page).to have_css('.sidebar-content', text: 'some_file2.txt')
    end

    it 'does show up new attachments' do
      page.find('.js-textarea').send_keys('new article with attachment')
      page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      expect(page).to have_text('mail001.box')
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].present? }
      click '.js-submit'
      expect(page).to have_css('.sidebar-content', text: 'mail001.box')
    end
  end

  describe 'Error “customer_id required” on Macro execution #4022', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.first) }
    let(:macro) { create(:macro, perform: { 'ticket.customer_id'=>{ 'pre_condition' => 'current_user.id', 'value' => nil, 'value_completion' => '' } }) }

    def authenticate
      ticket && macro

      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does set the agent as customer via macro' do
      click '.js-openDropdownMacro'
      page.find(:macro, macro.id).click
      expect(ticket.reload.customer_id).to eq(User.find_by(email: 'admin@example.com').id)
    end
  end

  context 'Assign user to multiple organizations #1573', authenticated_as: :authenticate do
    let(:organizations) { create_list(:organization, 20) }
    let(:customer) { create(:customer, organization: organizations[0], organizations: organizations[1..]) }
    let(:ticket)   { create(:ticket, group: Group.first, customer: customer) }

    def authenticate
      customer
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
      click '.tabsSidebar-tab[data-tab=customer]'
    end

    it 'shows only first 3 organizations and loads more on demand' do
      expect(page).to have_text(organizations[1].name)
      expect(page).to have_text(organizations[2].name)
      expect(page).to have_no_text(organizations[10].name)

      click '.js-showMoreOrganizations a'

      expect(page).to have_text(organizations[10].name)
    end
  end

  describe 'Allow additional usage of Ticket Number in (Zoom) URL #849' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    it 'does find the ticket by ticket number' do
      visit "#ticket/zoom/number/#{ticket.number}"
      expect(current_url).to include("ticket/zoom/#{ticket.id}")
    end

    it 'does fail properly for ticket numbers which are not found' do
      visit '#ticket/zoom/number/123456789'
      expect(page).to have_text('The requested Ticket could not be found.')
    end
  end

  describe 'Open ticket indicator coloring setting' do
    let(:elem)     { find('[data-tab="customer"]') }
    let(:customer) { create(:customer) }
    let(:group)    { Group.first }
    let(:ticket)   { create(:ticket, customer: customer, group: group) }

    before do
      Setting.set 'ui_sidebar_open_ticket_indicator_colored', state

      customer.update! preferences: { tickets_open: tickets_count }

      visit "ticket/zoom/#{ticket.id}"
    end

    context 'when enabled' do
      let(:state) { true }

      context 'with 1 ticket' do
        let(:tickets_count) { 1 }

        it 'does not highlight' do
          expect(elem)
            .to have_no_selector('.tabsSidebar-tab-count--danger, .tabsSidebar-tab-count--warning')
        end
      end

      context 'with 2 tickets' do
        let(:tickets_count) { 2 }

        it 'highlights as warning' do
          create(:ticket, customer: customer, group: group)

          expect(elem)
            .to have_no_selector('.tabsSidebar-tab-count--danger')
            .and have_css('.tabsSidebar-tab-count--warning')
        end
      end

      context 'with 3 tickets' do
        let(:tickets_count) { 3 }

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

  describe 'Display error of copied text in dark mode #5589' do
    let(:ticket)                     { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:ticket_number_copy_element) { 'span.ticket-number-copy svg.ticketNumberCopy-icon' }
    let(:expected_clipboard_content) { (Setting.get('ticket_hook') + ticket.number).to_s }
    let(:field)                      { find(:richtext) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'copies the ticket number without stylings' do
      find(ticket_number_copy_element).click

      # simulate a paste action
      within(:active_content) do
        field.send_keys('test ')
        field.send_keys([magic_key, 'v'])
        field.send_keys([:enter])
        field.send_keys('test ')
        field.send_keys([magic_key, 'v'])
        field.send_keys([:enter])
        field.send_keys('test ')
        field.send_keys([magic_key, 'v'])
        field.send_keys([:enter])
        field.send_keys('test ')
        field.send_keys([magic_key, 'v'])
        field.send_keys([:enter])
        click '.js-submit'
        wait.until do
          body = Ticket::Article.last.body
          body.include?('test') && body.exclude?('rgb')
        end
      end
    end

    it 'uses escape to remove last newline without stylings' do
      within(:active_content) do
        field.send_keys('test1')
        field.send_keys([:enter])
        field.send_keys([:enter])
        field.send_keys('test2')
        field.send_keys([:home])
        field.send_keys([:backspace])
        click '.js-submit'
        wait.until do
          body = Ticket::Article.last.body
          body.include?('test') && body.exclude?('rgb')
        end
      end
    end
  end

  describe 'Setting relative pending reminder times via macro results in an "Missing required value for field pending_time! error #5880', authenticated_as: :authenticate do
    let(:macro) { create(:macro, name: 'set custom pending', perform: { 'ticket.state_id' => { 'value' => '3' }, 'ticket.pending_time' => { 'operator' => 'relative', 'value' => '1', 'range' => 'week' } }) }

    def authenticate
      macro
      true
    end

    it 'does change the state via macro' do
      visit "#ticket/zoom/#{Ticket.first.id}"
      click '.js-openDropdownMacro'
      find(:macro, macro.id).click
      wait.until { Ticket.first.state.name == 'pending reminder' && Ticket.first.pending_time.present? }
    end
  end
end

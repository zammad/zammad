# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom', type: :system do
  # https://github.com/zammad/zammad/issues/3335
  context 'ticket state sort order maintained when locale is de-de', authenticated_as: :user do
    context 'when existing ticket is open' do
      let(:user)   { create(:customer, preferences: { locale: 'de-de' }) }
      let(:ticket) { create(:ticket, customer: user) }

      it 'shows ticket state dropdown options in sorted translated alphabetically order' do
        visit "ticket/zoom/#{ticket.id}"

        within :active_content, '.tabsSidebar' do
          expect(page).to have_css('select[name=state_id] option', count: 3)
          expect(all('select[name=state_id] option').map(&:text)).to eq(%w[geschlossen neu offen])
        end
      end
    end

    context 'when a new ticket is created' do
      let(:user) { create(:agent, preferences: { locale: 'de-de' }, groups: [permitted_group]) }
      let(:permitted_group) { create(:group) }

      it 'shows ticket state dropdown options in sorted order' do
        visit 'ticket/create'

        expect(page).to have_css('select[name=state_id] option', count: 6)
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
        type_input = find('input[name="type"]', visible: :all)

        expect(type_input.value).to eq('note')
        expect(page).to have_no_field('input[name=to]', visible: :visible)
        expect(find('[data-name=body]')).to have_text('This is a draft body from customer')
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
        expect(page).to have_no_css('.js-subscriptions span.avatar')

        # subscribe via macro
        click '.js-openDropdownMacro'
        find(:macro, 2).click # Subscribe macro button
        expect(page).to have_css('.js-subscriptions span.avatar')

        # unsubscribe via macro
        click '.js-openDropdownMacro'
        find(:macro, 3).click # Unsubscribe macro button

        expect(page).to have_no_css('.js-subscriptions span.avatar')

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
        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=gitlab] .js-tabCounter')
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
        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=github] .js-tabCounter')
      end
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

end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Popover', type: :system do

  # This test covers generic PopoverProvidable behavior
  it 'opening & auto-closing' do
    visit "#ticket/zoom/#{Ticket.first.id}"

    within :active_content do
      trigger_popover('.ticketZoom-header .js-avatar .user-popover')
    end

    # popover opened up
    expect(page).to have_css('.popover')

    visit '#dashboard'

    # move mouse to another location
    # for reliable popover re-spawning
    find('.menu').hover

    # popover is not visible when moving to another page without moving mouse
    # https://github.com/zammad/zammad/issues/4058
    expect(page).to have_no_css('.popover')

    visit "#ticket/zoom/#{Ticket.first.id}"

    # popover is not visible when moving back to the original page without moving mouse
    expect(page).to have_css('.ticketZoom')
    expect(page).to have_no_css('.popover')

    within :active_content do
      trigger_popover('.ticketZoom-header .js-avatar .user-popover')
    end

    # popover opens up again
    expect(page).to have_css('.popover')
  end

  it 'popover in overviews closes after overview update', ensure_threads_exited: true do
    ensure_websocket do
      visit '#ticket/view/all_unassigned'
    end

    within :active_content do
      trigger_popover('.user-popover')
    end

    expect(page).to have_css('.popover')

    Ticket.find(1).update!(owner: current_user)

    ensure_block_keeps_running do
      Sessions.thread_client(Sessions.sessions.first, nil)
    end

    expect(page).to have_no_css('.popover')
  end

  it 'popover of another agent closes after taskbar update' do
    ensure_websocket do
      visit "#ticket/zoom/#{Ticket.first.id}"
    end

    allow_any_instance_of(Taskbar).to receive(:update_preferences_infos)

    taskbar = Taskbar.where(key: 'Ticket-1', user_id: current_user.id).first

    within :active_content do
      taskbar.update! preferences: { 'tasks' => [{
        'user_id' => create(:admin).id,
        'apps'    => taskbar.preferences['tasks'].first['apps'],
      }] }
      TransactionDispatcher.commit

      trigger_popover('.js-attributeBar .user-popover')
    end

    expect(page).to have_css('.popover')

    taskbar.update! preferences: { 'tasks' => [] }
    TransactionDispatcher.commit

    expect(page).to have_no_css('.popover')
  end

  # The endpoint's own coverage lives in spec/requests/ticket/popover_spec.rb.
  context 'with the ticket popover in overviews', authenticated_as: :agent do
    let(:group)    { Group.find_by(name: 'Users') }
    let(:agent)    { create(:agent, groups: [group]) }
    let(:ticket)   { create(:ticket, group:, owner: agent, title: 'Login via SSO fails') }
    let(:summary)  { nil }
    let(:requests) { [] }

    let(:first_article) do
      create(:ticket_article, ticket:, body: 'Since resetting my password I can no longer log in via SSO.')
    end

    let(:last_article) do
      create(:ticket_article, :outbound_email, ticket:, body: 'I have reset the SSO link for your account.')
    end

    def popover_trigger
      "tr[data-id='#{ticket.id}'] .ticket-overview-popover"
    end

    def store_summary(content = summary)
      locale = Locale.find_by(locale: agent.locale)

      AI::StoredResult.create!(
        content: content,
        version: Service::AI::Feature::TicketSummarize.lookup_version({ articles: ticket.articles.without_system_notifications }, locale),
        **Service::AI::Feature::TicketSummarize.lookup_attributes({ ticket: }, locale),
      )
    end

    before do
      setup_ai_provider
      Setting.set('ai_assistance_ticket_summary', true)

      # Memoize on this thread, the stub below appends from the server's.
      requests

      allow_any_instance_of(Ticket::PopoverController).to receive(:show).and_wrap_original do |method, *args|
        requests << method.receiver.params[:id]
        method.call(*args)
      end

      # The number is only a column of this overview's medium view mode.
      overview = Overview.find_by(link: 'my_assigned')
      overview.update!(view: overview.view.merge('s' => ['number', *overview.view['s']]))

      first_article && last_article
      store_summary if summary

      visit '#ticket/view/my_assigned'
    end

    it 'opens on the title and on the number' do
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: ticket.title)

      find('.menu').hover

      expect(page).to have_no_css('.popover')

      within :active_content do
        trigger_popover(popover_trigger, text: ticket.number)
      end

      # The title sits in the tip's header, so only the articles tell a loaded tip apart.
      expect(page).to have_css('.popover', text: %r{latest article}i)
    end

    it 'shows the first and the latest article without a stored summary', :aggregate_failures do
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: %r{first article}i)
        .and have_css('.popover', text: 'Since resetting my password I can no longer log in via SSO.')
        .and have_css('.popover', text: %r{latest article}i)
        .and have_css('.popover', text: 'I have reset the SSO link for your account.')

      # The side of the bubble tells a colleague from the customer, the avatar who wrote it.
      expect(page).to have_css('.ticket-overview-popover-article--right .textBubble',
                               exact_text: 'Since resetting my password I can no longer log in via SSO.')
        .and have_css('.ticket-overview-popover-article--left .textBubble',
                      exact_text: 'I have reset the SSO link for your account.')
        .and have_css('.ticket-overview-popover-article .avatar', count: 2)
    end

    context 'with an internal note as the latest article' do
      let(:last_article) do
        create(:ticket_article, :internal_note, ticket:, body: 'Checked this with the second level.')
      end

      it 'marks the internal note' do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        expect(page).to have_css('.ticket-overview-popover-article.is-internal',
                                 text: 'Checked this with the second level.')
      end
    end

    it 'copies the ticket number' do
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      # The loaded content replaces the whole tip, including the copy icon of the title.
      expect(page).to have_css('.popover', text: %r{latest article}i)

      find('.js-ticketOverviewPopoverCopyNumber').click

      expect(page).to have_css('.tooltip', text: 'Copied!')
    end

    it 'does not request the content again for an unchanged ticket', :aggregate_failures do
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: %r{latest article}i)

      find('.menu').hover

      expect(page).to have_no_css('.popover')

      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: %r{latest article}i)
      expect(requests).to eq([ticket.id.to_s])
    end

    it 'shows a summary that was stored after the response was cached', :aggregate_failures do
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: %r{first article}i)

      store_summary('customer_request' => 'Mara wants to log in via SSO again.')

      # A stored summary does not touch the ticket, so only the expiry of the cached
      #   entry can bring it to the row. Expire it right away instead of waiting for it.
      page.execute_script("App.Config.get('TicketOverview', 'PopoverProviders').dataCacheTTL = 0")

      find('.menu').hover

      expect(page).to have_no_css('.popover')

      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: 'Mara wants to log in via SSO again.')
    end

    it 'cancels the request of a tip that hid before its response arrived', :aggregate_failures do
      response_gate = Queue.new
      request_entered = Queue.new

      allow_any_instance_of(Ticket::PopoverController).to receive(:show).and_wrap_original do |method, *args|
        requests << method.receiver.params[:id]
        request_entered << true
        response_gate.pop(timeout: 10)
        method.call(*args)
      end

      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover')

      # Hiding the tip before the request reached the server would abort it unrecorded.
      request_entered.pop(timeout: 10)

      find('.menu').hover

      expect(page).to have_no_css('.popover')
      expect(page.evaluate_script(<<~JS)).to be(false)
        Object.keys(App.Ajax.current()).some((id) => id.startsWith('ticket-overview-popover') && id.endsWith('-#{ticket.id}'))
      JS

      response_gate.close

      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: %r{latest article}i)
      expect(requests).to eq([ticket.id.to_s] * 2)
    ensure
      response_gate&.close
    end

    # Moves the pointer away while the content of the tip is still loading, and lets the response
    #   arrive while the tip still waits to hide. The real hide delay of 100 ms leaves too little
    #   room for that, so it is stretched.
    def leave_while_loading
      response_gate = Queue.new
      request_entered = Queue.new

      allow_any_instance_of(Ticket::PopoverController).to receive(:show).and_wrap_original do |method, *args|
        requests << method.receiver.params[:id]
        request_entered << true
        response_gate.pop(timeout: 10)
        method.call(*args)
      end

      trigger = within(:active_content) do
        trigger_popover(popover_trigger, text: ticket.title)
        find(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover')
      request_entered.pop(timeout: 10)

      trigger.execute_script("$(this).data('bs.popover').options.delay = { show: 100, hide: 1000 }")

      find('.menu').hover
      response_gate.close
      wait.until { page.evaluate_script('$.active').zero? }
    ensure
      response_gate&.close
    end

    it 'keeps the tip closed when its response arrives after the pointer left', :aggregate_failures do
      leave_while_loading

      expect(page).to have_no_css('.popover')

      # Only a response that was handled instead of aborted on hide is cached for the next tip.
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover', text: %r{latest article}i)
      expect(requests).to eq([ticket.id.to_s])
    end

    it 'shows the loaded content when the pointer returns before the tip hid', :aggregate_failures do
      leave_while_loading

      within :active_content do
        find(popover_trigger, text: ticket.title).hover
      end

      expect(page).to have_css('.popover', text: %r{latest article}i)
      expect(requests).to eq([ticket.id.to_s])
    end

    it 'opens no ticket on hover and keeps the row link working', :aggregate_failures do
      within :active_content do
        trigger_popover(popover_trigger, text: ticket.title)
      end

      expect(page).to have_css('.popover')
      expect(page).to have_no_css('.ticketZoom')

      find(popover_trigger, text: ticket.title).click

      expect(page).to have_css('.ticketZoom-header', text: ticket.title)
    end

    # The detail search lists tickets the way an overview does, so it shows the same popover.
    context 'with the detail search' do
      before do
        visit "#search/#{ticket.number}"
      end

      it 'shows the popover on the title and on the number', :aggregate_failures do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        expect(page).to have_css('.popover', text: %r{latest article}i)

        find('.menu').hover

        expect(page).to have_no_css('.popover')

        within :active_content do
          trigger_popover(popover_trigger, text: ticket.number)
        end

        expect(page).to have_css('.popover', text: %r{latest article}i)
      end
    end

    context 'with a single article' do
      let(:last_article) { first_article }

      it 'shows that article once', :aggregate_failures do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        expect(page).to have_css('.popover', text: %r{latest article}i)
        expect(page).to have_no_css('.popover', text: %r{first article}i)
      end
    end

    context 'with a stored summary' do
      let(:summary) do
        {
          'customer_request' => 'Mara wants to log in via SSO again.',
          'customer_emotion' => '🙁',
          'customer_mood'    => 'negative',
        }
      end

      it 'shows the intent, the sentiment and the accuracy note', :aggregate_failures do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        expect(page).to have_css('.popover', text: 'Mara wants to log in via SSO again.')
          .and have_css('.popover', text: %r{customer intent}i)
          .and have_css('.ticket-overview-popover-badge--sentiment', text: %r{customer sentiment}i)
          .and have_css('.ticket-overview-popover-badge--sentiment', text: 'negative')
          .and have_css('.popover', text: 'Be sure to check AI-generated content for accuracy.')

        # The intent covers the first article, so only the latest one is repeated.
        expect(page).to have_no_css('.popover', text: %r{first article}i)
      end

      it 'opens the ticket with the summary sidebar' do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        find('.ticket-overview-popover-badge--sentiment').click

        within :active_content do
          expect(page).to have_css('.tabsSidebar-tab[data-tab="summary"].active')
        end
      end

      context 'without a customer intent' do
        let(:summary) do
          {
            'customer_emotion' => '🙁',
            'customer_mood'    => 'negative',
          }
        end

        # The accuracy note belongs to the intent, so the sentiment is not shown on its own.
        it 'shows no AI-generated content at all', :aggregate_failures do
          within :active_content do
            trigger_popover(popover_trigger, text: ticket.title)
          end

          expect(page).to have_css('.popover', text: %r{first article}i)
          expect(page).to have_no_css('.ticket-overview-popover-badge--sentiment')
        end
      end
    end

    context 'with an open checklist', current_user_id: 1 do
      before do
        Setting.set('checklist', true)

        create(:checklist, ticket:, item_count: 3).items.first.update!(checked: true)
      end

      it 'shows the complete and the total count' do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        expect(page).to have_css('.ticket-overview-popover-badge', text: %r{checked\s+1 of 3}i)
      end

      it 'opens the ticket with the checklist sidebar', :aggregate_failures do
        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        find('.ticket-overview-popover-badge', text: %r{checked}i).click

        within :active_content do
          expect(page).to have_css('.tabsSidebar-tab[data-tab="checklist"].active')
        end

        # The link is taken over by the task instead of staying in the address bar.
        expect(page).to have_current_path(%r{\#ticket/zoom/#{ticket.id}$}, url: true)
      end

      it 'falls back to the first sidebar tab when the deep link names no rendered tab', :aggregate_failures do
        Setting.set('checklist', false)
        wait.until { page.evaluate_script("App.Config.get('checklist')") == false }

        visit "#ticket/zoom/#{ticket.id}/sidebar/checklist"

        within :active_content do
          expect(page).to have_css('.tabsSidebar-tab[data-tab="ticket"].active')
        end

        # A name that is no valid selector reaches the sidebar just as well.
        visit "#ticket/zoom/#{ticket.id}/sidebar/checklist]"

        within :active_content do
          expect(page).to have_css('.tabsSidebar-tab[data-tab="ticket"].active')
        end
      end

      it 'switches the sidebar of a ticket that is already open' do
        visit "#ticket/zoom/#{ticket.id}"

        within :active_content do
          expect(page).to have_css('.tabsSidebar-tab[data-tab="ticket"].active')
        end

        visit '#ticket/view/my_assigned'

        within :active_content do
          trigger_popover(popover_trigger, text: ticket.title)
        end

        find('.ticket-overview-popover-badge', text: %r{checked}i).click

        within :active_content do
          expect(page).to have_css('.tabsSidebar-tab[data-tab="checklist"].active')
        end
      end
    end

    context 'when logged in as customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }
      let(:ticket)   { create(:ticket, group:, customer:, title: 'Login via SSO fails') }

      before do
        visit '#ticket/view/my_tickets'
      end

      it 'shows the title tooltip without a popover', :aggregate_failures do
        within :active_content do
          expect(page).to have_css("tr[data-id='#{ticket.id}'] td[title='#{ticket.title}']")
          expect(page).to have_no_css('.ticket-overview-popover')
        end

        expect(requests).to be_empty
      end
    end
  end

  context 'when a ticket has no customer' do
    let(:group)  { Group.find_by(name: 'Users') }
    let(:ticket) { create(:ticket, group:, customer: User.find(1)) }

    shared_examples 'showing the customer cell without popover' do
      it 'shows the customer cell without popover' do
        row = find("tr.item[data-id='#{ticket.id}']")
        cell = row.find('td', exact_text: '-')

        expect(row).to have_no_css('.user-popover')

        cell.hover
        expect(page).to have_no_css('.popover')
      end
    end

    context 'when shown in an overview' do
      before do
        ticket

        visit '#ticket/view/all_unassigned'
      end

      it 'keeps the popover on the customer cell of other tickets' do
        within :active_content do
          expect(page).to have_css("tr.item[data-id='#{Ticket.first.id}'] .user-popover[data-id='#{Ticket.first.customer_id}']")
        end
      end

      it_behaves_like 'showing the customer cell without popover'
    end

    context 'when shown in a ticket list' do
      let(:source_ticket) { create(:ticket, group:, customer: User.find(1)) }

      before do
        ticket

        visit "#ticket/zoom/#{source_ticket.id}"

        within :active_content do
          find('[data-tab="ticket"] .js-actions').click
          click('[data-type="ticket-merge"]')
        end

        modal_ready
      end

      it_behaves_like 'showing the customer cell without popover'
    end
  end

  def trigger_popover(selector, **)
    find(selector, **) do |elem|
      elem.evaluate_script('Object.keys($(this).data()).includes("bs.popover")')
    end.hover
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Viewers > Live Users', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)         { Group.find_by(name: 'Users') }
  let(:agent)         { create(:agent, groups: [group]) }
  let(:another_agent) { create(:agent, groups: [group]) }
  let(:third_agent)   { create(:agent, groups: [group]) }
  let(:customer)      { create(:customer) }
  let(:ticket)        { create(:ticket, customer: customer, group: group) }

  def wait_for_viewers_subscription(number: 1)
    wait_for_gql('apps/mobile/pages/ticket/graphql/subscriptions/live-user/ticketLiveUserUpdates.graphql', number: number)
  end

  def open_viewers_dialog()
    visit "/tickets/#{ticket.id}"
    wait_for_viewers_subscription
    find('[role="button"][title="Show ticket viewers"]').click
  end

  def update_taskbar_item(taskbar_item, state, agent_id, number)
    # Special case: By design, it is only allowed to update the taskbar of the current user.
    # We need to work around this, otherwise this test would fail.
    UserInfo.current_user_id = agent_id
    taskbar_item.update!(state: state)
    UserInfo.current_user_id = agent.id

    wait_for_viewers_subscription(number: number)
  end

  context 'when opening viewers', authenticated_as: :agent do
    it 'shows the users currently looking at the ticket' do # rubocop:disable RSpec/ExampleLength
      taskbar_item = create(:taskbar, user_id: another_agent.id, key: "Ticket-#{ticket.id}", app: 'mobile')
      open_viewers_dialog

      # No idle viewers.
      expect(page).to have_no_text('Opened in tabs')

      # One active viewer, without editing.
      expect(page)
        .to have_text('Viewing ticket')
        .and have_no_text(agent.fullname)
        .and have_text(another_agent.fullname)
        .and have_no_css('.icon.icon-mobile-edit')

      # Checking pencil icon.
      update_taskbar_item(taskbar_item, { editing: true }, another_agent.id, 2)

      expect(page).to have_css('.icon.icon-mobile-edit')

      # Checking idle.
      travel_to 10.minutes.ago
      update_taskbar_item(taskbar_item, { editing: false }, another_agent.id, 3)
      travel_back

      expect(page)
        .to have_text('Opened in tabs')
        .and have_no_text(agent.fullname)
        .and have_no_text('Viewing ticket')
        .and have_text(another_agent.fullname)
        .and have_no_css('.icon.icon-mobile-edit')

      # Another viewer appears.
      another_taskbar_item = create(:taskbar, user_id: third_agent.id, key: "Ticket-#{ticket.id}", app: 'mobile')
      update_taskbar_item(another_taskbar_item, { editing: true }, third_agent.id, 4)

      wait_for_viewers_subscription(number: 5)

      expect(page)
        .to have_text('Opened in tabs')
        .and have_text('Viewing ticket')
        .and have_no_text(agent.fullname)
        .and have_text(another_agent.fullname)
        .and have_text(third_agent.fullname)
        .and have_css('.icon.icon-mobile-edit')
    end

    context 'when editing is started on mobile' do
      it 'updates the other session' do
        visit "/tickets/#{ticket.id}"

        using_session(:customer) do
          login(
            username: another_agent.login,
            password: 'test',
          )

          visit "/tickets/#{ticket.id}"
        end

        open_viewers_dialog

        expect(page)
          .to have_text(another_agent.fullname)
          .and have_no_css('.icon.icon-mobile-edit')

        using_session(:customer) do
          visit "/tickets/#{ticket.id}/information"

          wait_for_form_to_settle('form-ticket-edit')

          within_form(form_updater_gql_number: 1) do
            find_input('Ticket title').type('New Title')
          end
        end

        wait_for_viewers_subscription(number: 2)

        expect(page)
          .to have_text('Viewing ticket')
          .and have_text(another_agent.fullname)
          .and have_css('.icon.icon-mobile-edit')
      end
    end

    context 'when editing is started on desktop' do
      it 'updates the other session' do
        visit "/tickets/#{ticket.id}"

        using_session(:customer) do
          login(
            username:    another_agent.login,
            password:    'test',
            remember_me: false,
            app:         :desktop,
          )

          visit "/#ticket/zoom/#{ticket.id}", app: :desktop
        end

        open_viewers_dialog

        expect(page)
          .to have_text(another_agent.fullname)
          .and have_no_css('.icon.icon-mobile-desktop-edit')

        using_session(:customer) do
          within :active_content, '.tabsSidebar' do
            select 'closed', from: 'State'
          end
        end

        wait_for_viewers_subscription(number: 2)

        expect(page)
          .to have_text('Viewing ticket')
          .and have_text(another_agent.fullname)
          .and have_css('.icon.icon-mobile-desktop-edit')
      end
    end

    context 'when current user is using both desktop and mobile' do
      it 'shows correct icons' do
        visit "/tickets/#{ticket.id}"

        using_session(:customer) do
          login(
            username:    agent.login,
            password:    'test',
            remember_me: false,
            app:         :desktop,
          )

          visit "/#ticket/zoom/#{ticket.id}", app: :desktop

          within :active_content, '.tabsSidebar' do
            select 'closed', from: 'State'
          end
        end

        open_viewers_dialog

        expect(page)
          .to have_text('Viewing ticket')
          .and have_text(agent.fullname)
          .and have_css('.icon.icon-mobile-desktop-edit')
      end
    end
  end
end

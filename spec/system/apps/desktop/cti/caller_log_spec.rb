# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Caller log', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  # The seeded agent role already carries cti.agent.
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer, firstname: 'Franz', lastname: 'Bauer') }

  let(:missed_call) do
    create(:cti_log,
           direction:   'in',
           state:       'hangup',
           comment:     'noAnswer',
           from:        '4930609854180',
           to:          '4930609811111',
           done:        false,
           preferences: {
             from: [
               { caller_id: '4930609854180', comment: nil, level: 'known', object: 'User', o_id: customer.id, user_id: customer.id },
             ],
           })
  end

  let(:calls)         { table_rows('Caller log') }
  let(:customer_link) { main_content.get_by_role('link', name: "Avatar (#{customer.fullname})") }

  def phone_link(number)
    main_content.get_by_role('link', name: number, exact: true)
  end

  before do
    Setting.set('cti_integration', true)
    missed_call
  end

  context 'with the cti.agent permission' do
    it 'shows the caller log' do
      open_desktop('/cti')

      expect(main_content).to contain_text('Franz Bauer')
      expect(main_content).to contain_text('Not reached')
      expect(phone_link('+49 30 609854180')).to have_attribute('href', 'tel:4930609854180')
      expect(phone_link('+49 30 609811111')).to have_attribute('href', 'tel:4930609811111')
    end

    it 'opens the matched user through the avatar' do
      open_desktop('/cti')

      customer_link.click

      expect(page).to have_url(%r{/desktop/users/#{customer.id}$})
      expect(main_content).to contain_text('Franz Bauer')
    end

    # The same gate as the user popover: without ticket or user permissions there is nothing to open.
    context 'with only the cti.agent permission' do
      let(:agent)         { create(:agent, roles: [role_cti_only]) }
      let(:role_cti_only) { create(:role, permission_names: %w[cti.agent]) }

      it 'names the matched user without a link' do
        open_desktop('/cti')

        expect(main_content).to contain_text('Franz Bauer')
        expect(customer_link).to have_count(0)
      end
    end

    it 'shows a new call and its state changes without reloading' do
      open_desktop('/cti')
      wait_for_subscription_start('ctiLogUpdates', scope: agent)

      expect(calls).to have_count(1)

      incoming_call = create(:cti_log, direction: 'in', state: 'newCall', from: '4930100099999', to: '4930609811111', done: false)

      expect(calls).to have_count(2)
      expect(phone_link('+49 30 100099999')).to be_visible
      expect(main_content).to contain_text('Ringing…')

      # The newest call sits on top.
      expect(calls.first).to have_attribute('data-item-id', Gql::ZammadSchema.id_from_object(incoming_call))

      incoming_call.update!(state: 'answer', done: true)

      expect(main_content).to contain_text('Connected')
      expect(main_content).to not_contain_text('Ringing…')

      incoming_call.destroy!

      expect(calls).to have_count(1)
      expect(phone_link('+49 30 100099999')).to have_count(0)
    end

    # The navigation entry is fed by the sidebar query and its subscription, not by the table.
    context 'with the caller notification on' do
      let(:agent) { create(:agent, preferences: { cti: true }) }

      it 'shows a ringing call in the navigation until it is answered' do
        open_desktop('/cti')
        # The push replaces the query result as a whole, a late initial answer would hide the call.
        wait_for_query('ctiSidebar')
        wait_for_subscription_start('ctiSidebarUpdates', scope: agent)

        ringing_calls = page_navigation.get_by_role('list', name: 'Ringing calls')

        expect(ringing_calls).to have_count(0)

        incoming_call = create(:cti_log, direction: 'in', state: 'newCall', from: '4930100099999', to: '4930609811111', done: false)

        expect(ringing_calls).to contain_text('+49 30 100099999')

        incoming_call.update!(state: 'answer')

        expect(ringing_calls).to have_count(0)
      end
    end

    # The only place the re-match on the server and the caller log subscription meet.
    context 'with a call from an unknown number' do
      before { create(:cti_log, :inbound, :not_reached, from: '4930100099999', to: '4930609811111') }

      it 'creates a user for the caller, opens a ticket for them and names them in the entry' do
        open_desktop('/cti')
        wait_for_subscription_start('ctiLogUpdates', scope: agent)

        expect(phone_link('+49 30 100099999')).to have_attribute('href', 'tel:4930100099999')

        main_content.get_by_role('button', name: 'New user').click

        new_user = flyout('New user')
        fill_field('First name', 'Erika', within: new_user)
        fill_field('Last name', 'Mustermann', within: new_user)
        new_user.get_by_role('button', name: 'Create').click

        expect(page).to have_url(%r{/desktop/tickets/create/[^?]+\?customer_id=\d+$})

        user = User.find_by!(firstname: 'Erika', lastname: 'Mustermann')

        expect(user.phone).to eq('+49 30 100099999')
        expect(page).to have_url(%r{\?customer_id=#{user.id}$})
        wait_for_form_to_settle('ticket-create')

        expect(field('Customer', within: main_content)).to contain_text('Erika Mustermann')

        # Leaving before the customer sidebar has shown up would teleport its content into
        #   the tab kept alive off the document, and the next patch of it throws.
        expect(content_sidebar).to contain_text('Erika Mustermann')

        # Back through the navigation, not a reload.
        page_navigation.get_by_role('link', name: 'Phone').click

        expect(main_content).to contain_text('Erika Mustermann')
      end
    end

    it 'marks a call as handled and back' do
      open_desktop('/cti')

      handled = main_content.get_by_role('checkbox')

      handled.click
      wait_until { missed_call.reload.done }

      expect(handled).to have_attribute('aria-checked', 'true')
      expect(calls.first).to contain_class('opacity-50')

      handled.click
      wait_until { !missed_call.reload.done }

      expect(handled).to have_attribute('aria-checked', 'false')
      expect(calls.first).to not_contain_class('opacity-50')
    end

    # The old caller log stopped at cti_config[:view_limit] (default 60); this one pages on scroll.
    context 'with more calls than the old view limit' do
      let(:older_calls) do
        Array.new(Cti::Log.view_limit + 10) do |index|
          travel 1.second
          create(:cti_log, from: "49301000#{format('%04d', index)}", to: '4930609811111')
        end
      end

      before { older_calls }

      it 'loads further calls as the agent scrolls down' do
        open_desktop('/cti')

        expect(calls).to have_count(25)
        expect(phone_link(older_calls.last.from_pretty)).to be_visible
        expect(phone_link(older_calls.first.from_pretty)).to have_count(0)

        # Two further pages of 25 reach past the old limit; the oldest call sits on the last one.
        [50, older_calls.size + 1].each do |loaded_rows|
          calls.last.scroll_into_view_if_needed

          expect(calls).to have_count(loaded_rows)
        end

        expect(phone_link(older_calls.first.from_pretty)).to be_visible
      end
    end
  end

  context 'without the cti.agent permission' do
    let(:agent)              { create(:agent, roles: [role_without_cti]) }
    let(:role_without_cti)   { create(:role, permission_names: %w[ticket.agent]) }

    it 'refuses access' do
      open_desktop('/cti')

      expect(page.locator('body')).to contain_text('Forbidden')
      expect(page.locator('body')).to not_contain_text('Franz Bauer')
    end
  end
end

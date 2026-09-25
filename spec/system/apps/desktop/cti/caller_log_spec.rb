# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Caller log', app: :desktop_view, authenticated_as: :agent, type: :system do
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

  before do
    Setting.set('cti_integration', true)
    missed_call
  end

  context 'with the cti.agent permission' do
    it 'shows the caller log' do
      visit '/cti'

      within 'main' do
        expect(page).to have_text('Franz Bauer')
          .and have_text('Not reached')
          .and have_link('+49 30 609854180', href: 'tel:4930609854180')
          .and have_link('+49 30 609811111', href: 'tel:4930609811111')
      end
    end

    it 'opens the matched user through the avatar' do
      visit '/cti'

      within 'main' do
        find("a[href='/desktop/users/#{customer.id}']").click
      end

      expect(page).to have_current_path("/desktop/users/#{customer.id}")
      expect(page).to have_text('Franz Bauer')
    end

    # The same gate as the user popover: without ticket or user permissions there is nothing to open.
    context 'with only the cti.agent permission' do
      let(:agent) { create(:agent, roles: [role_cti_only]) }
      let(:role_cti_only) { create(:role, permission_names: %w[cti.agent]) }

      it 'names the matched user without a link' do
        visit '/cti'

        within 'main' do
          expect(page).to have_text('Franz Bauer')
            .and have_no_link(href: "/desktop/users/#{customer.id}")
        end
      end
    end

    it 'shows a new call and its state changes without reloading' do
      visit '/cti'
      wait_for_subscription_start('ctiLogUpdates')

      within 'main' do
        expect(page).to have_css('[data-item-id]', count: 1)

        incoming_call = create(:cti_log, direction: 'in', state: 'newCall', from: '4930100099999', to: '4930609811111', done: false)

        expect(page).to have_css('[data-item-id]', count: 2)
          .and have_link(href: 'tel:4930100099999')
          .and have_text('Ringing…')

        # The newest call sits on top.
        expect(first('[data-item-id]')['data-item-id']).to eq(Gql::ZammadSchema.id_from_object(incoming_call))

        incoming_call.update!(state: 'answer', done: true)

        expect(page).to have_text('Connected')
          .and have_no_text('Ringing…')

        incoming_call.destroy!

        expect(page).to have_css('[data-item-id]', count: 1)
          .and have_no_link(href: 'tel:4930100099999')
      end
    end

    # The navigation entry is fed by the sidebar query and its subscription, not by the table.
    context 'with the caller notification on' do
      let(:agent) { create(:agent, preferences: { cti: true }) }

      it 'shows a ringing call in the navigation until it is answered' do
        visit '/cti'
        wait_for_subscription_start('ctiSidebarUpdates')

        within '#page-navigation' do
          expect(page).to have_no_css('ul[aria-label="Ringing calls"]')

          incoming_call = create(:cti_log, direction: 'in', state: 'newCall', from: '4930100099999', to: '4930609811111', done: false)

          within 'ul[aria-label="Ringing calls"]' do
            expect(page).to have_text('+49 30 100099999')
          end

          incoming_call.update!(state: 'answer')

          expect(page).to have_no_css('ul[aria-label="Ringing calls"]')
        end
      end
    end

    # The only place the re-match on the server and the caller log subscription meet.
    context 'with a call from an unknown number' do
      before { create(:cti_log, :inbound, :not_reached, from: '4930100099999', to: '4930609811111') }

      it 'creates a user for the caller, opens a ticket for them and names them in the entry' do
        visit '/cti'
        wait_for_subscription_start('ctiLogUpdates')

        within 'main' do
          expect(page).to have_link('+49 30 100099999', href: 'tel:4930100099999')

          find('button[aria-label="New user"]').click
        end

        within '#flyout-user-create-flyout' do
          find_input('First name').type('Erika')
          find_input('Last name').type('Mustermann')

          click_on 'Create'
        end

        expect(page).to have_current_path(%r{/desktop/tickets/create/[^?]+\?customer_id=\d+$})

        user = User.find_by!(firstname: 'Erika', lastname: 'Mustermann')

        expect(user.phone).to eq('+49 30 100099999')
        expect(page).to have_current_path(%r{\?customer_id=#{user.id}$})
        wait_for_form_to_settle('ticket-create')

        expect(find_autocomplete('Customer')).to have_text('Erika Mustermann')

        # Leaving before the customer sidebar has shown up would teleport its content into
        #   the tab kept alive off the document, and the next patch of it throws.
        expect(page).to have_css('#ticketSidebar', text: 'Erika Mustermann')

        # Back through the navigation, not a reload.
        within '#page-navigation' do
          click_on 'Phone'
        end

        within 'main' do
          expect(page).to have_text('Erika Mustermann')
        end
      end
    end

    it 'marks a call as handled and back' do
      visit '/cti'

      within 'main' do
        find('[role="checkbox"]').click

        wait.until { missed_call.reload.done }

        expect(page).to have_css('[role="checkbox"][aria-checked="true"]')
          .and have_css('[data-item-id].opacity-50')

        find('[role="checkbox"]').click

        wait.until { !missed_call.reload.done }

        expect(page).to have_css('[role="checkbox"][aria-checked="false"]')
          .and have_no_css('[data-item-id].opacity-50')
      end
    end

    # The old caller log stopped at cti_config[:view_limit] (default 60); this one pages on scroll.
    context 'with more calls than the old view limit' do
      let(:call_count) { Cti::Log.view_limit + 10 }

      let(:number_of) { ->(index) { "49301000#{format('%04d', index)}" } }

      def scroll_caller_log_to_bottom
        page.execute_script(<<~JS)
          const container = document.querySelector('main .overflow-y-auto')
          container.scrollTop = container.scrollHeight
        JS
      end

      before do
        call_count.times do |index|
          travel 1.second
          create(:cti_log, from: number_of.call(index), to: '4930609811111')
        end
      end

      it 'loads further calls as the agent scrolls down' do
        visit '/cti'

        within 'main' do
          expect(page).to have_css('[data-item-id]', count: 25)
            .and have_link(href: "tel:#{number_of.call(call_count - 1)}")
            .and have_no_link(href: "tel:#{number_of.call(0)}")

          # Two further pages of 25 reach past the old limit; the oldest call sits on the last one.
          [50, call_count + 1].each do |loaded_rows|
            scroll_caller_log_to_bottom

            expect(page).to have_css('[data-item-id]', count: loaded_rows)
          end

          expect(page).to have_link(href: "tel:#{number_of.call(0)}")
        end
      end
    end
  end

  context 'without the cti.agent permission' do
    let(:agent)              { create(:agent, roles: [role_without_cti]) }
    let(:role_without_cti)   { create(:role, permission_names: %w[ticket.agent]) }

    it 'refuses access' do
      visit '/cti'

      expect(page).to have_text('Forbidden')
        .and have_no_text('Franz Bauer')
    end
  end
end

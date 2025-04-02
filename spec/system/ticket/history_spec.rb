# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket history', time_zone: 'Europe/London', type: :system do
  let(:group)    { create(:group) }
  let(:subgroup) { create(:group, parent: group) }
  let(:ticket)   { create(:ticket, group: group) }

  context 'with German locale', authenticated_as: :authenticate do
    let(:admin_de) { create(:admin, :groupable, preferences: { locale: 'de-de' }, group: [group, subgroup]) }

    def authenticate
      Time.use_zone('UTC') do
        freeze_time

        travel_to DateTime.parse('2021-01-22 13:40: UTC')
        current_time = Time.current
        ticket_article = create(:ticket_article, ticket: ticket, internal: true)
        ticket.update!(
          title:                    'New Ticket Title',
          state:                    Ticket::State.lookup(name: 'open'),
          last_owner_update_at:     current_time,
          priority:                 Ticket::Priority.lookup(name: '1 low'),
          group:                    subgroup,
          last_contact_at:          current_time,
          last_contact_customer_at: current_time,
          last_contact_agent_at:    current_time,
        )
        ticket_article.update! internal: false

        travel_to DateTime.parse('2021-04-06 23:30:00 UTC')
        current_time = Time.current
        ticket.update!(
          state:                        Ticket::State.lookup(name: 'pending close'),
          priority:                     Ticket::Priority.lookup(name: '3 high'),
          last_contact_at:              current_time,
          last_contact_customer_at:     current_time,
          last_contact_agent_at:        current_time,
          pending_time:                 current_time,
          first_response_escalation_at: current_time,
        )
        ticket_article.update! internal: true

        travel_back
      end

      admin_de
    end

    before do
      visit '/'

      # Suppress the modal dialog that invites to contributions for translations that are < 90% as this breaks the tests for de-de.
      page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"

      visit "#ticket/zoom/#{ticket.id}"
      find('[data-tab="ticket"] .js-actions').click
      click('[data-type="ticket-history"]')
    end

    it 'shows group name in human readable form' do
      expect(page).to have_text("#{group.name_last} › #{subgroup.name_last}")
    end

    it "translates timestamp when attribute's tag is datetime" do
      expect(page).to have_css('li', text: %r{22.01.2021 13:40})
    end

    it 'does not include time with UTC format' do
      expect(page).to have_no_text(%r{ UTC})
    end

    it 'translates value when attribute is state' do
      expect(page).to have_css('li', text: %r{Ticket Status von 'neu'})
    end

    it 'translates value when attribute is priority' do
      expect(page).to have_css('li', text: %r{Ticket Priorität von '1 niedrig'})
    end

    it 'translates value when attribute is internal' do
      expect(page).to have_css('li', text: %r{Artikel intern von 'true'})
    end

    it 'translates last_contact_at display attribute' do
      expect(page).to have_css('li', text: %r{Ticket Letzter Kontakt von '22.01.2021 13:40' → '07.04.2021 00:30'})
    end

    it 'translates last_contact_customer_at display attribute' do
      expect(page).to have_css('li', text: %r{Ticket Letzter Kontakt \(Kunde\) von '22.01.2021 13:40' → '07.04.2021 00:30'})
    end

    it 'translates last_contact_agent_at display attribute' do
      expect(page).to have_css('li', text: %r{Ticket Letzter Kontakt \(Agent\) von '22.01.2021 13:40' → '07.04.2021 00:30'})
    end

    it 'translates pending_time display attribute' do
      expect(page).to have_css('li', text: %r{Ticket Warten bis '07.04.2021 00:30'})
    end
  end

  context 'with time-based trigger' do
    let(:group)   { Group.first }
    let(:trigger) { create(:trigger, activator: 'time') }

    before do
      UserInfo.ensure_current_user_id do
        trigger.performed_on(ticket, activator_type: 'reminder_reached')
      end

      visit "#ticket/zoom/#{ticket.id}"
      find('[data-tab="ticket"] .js-actions').click
      click('[data-type="ticket-history"]')
    end

    it 'shows information that trigger was performed' do
      text = "trigger '#{trigger.name}' was performed because pending reminder was reached"

      expect(page).to have_css('li', text: Regexp.new(text))
    end
  end
end

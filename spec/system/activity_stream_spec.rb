# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do
  context 'when Ticket has name attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, name: 'name', display: 'Name')
      ObjectManager::Attribute.migration_execute
      true
    end

    let(:ticket)     { Ticket.first }
    let(:name_value) { 'activity stream test' }

    before do
      ticket.update! name: name_value
    end

    it 'shows ticket title in activity stream' do
      visit '/'

      within '.sidebar' do
        expect(page)
          .to have_no_text(name_value)
          .and have_text(ticket.title)
      end
    end
  end

  context 'when the activity stream is turned off', authenticated_as: :authenticate do
    def authenticate
      Setting.set('dashboard_activity_stream', false)
      true
    end

    it 'does not show the activity stream' do
      visit '/'

      within :active_content do
        expect(page).to have_text('My Stats')
        expect(page).to have_no_css('.js-activityContent', visible: :all)
      end
    end
  end

  context 'when the settings change while the dashboard is open' do
    before do
      create(:ticket, group: Group.find_by(name: 'Users'), title: 'Ticket of a colleague')

      visit '/'
      wait_for_authenticated_session
    end

    it 'hides the activities of colleagues once limited to own activities' do
      within '.sidebar' do
        expect(page).to have_text('Ticket of a colleague')
      end

      create(:ticket, group: Group.find_by(name: 'Users'), title: 'Own ticket', created_by_id: User.find_by(email: 'admin@example.com').id)

      Setting.set('dashboard_activity_stream_own', true)

      within '.sidebar' do
        expect(page).to have_text('Own ticket').and have_no_text('Ticket of a colleague')
      end
    end

    it 'hides the activity stream once turned off' do
      within '.sidebar' do
        expect(page).to have_text('Ticket of a colleague')
      end

      Setting.set('dashboard_activity_stream', false)

      within :active_content do
        expect(page).to have_no_css('.js-activityContent', visible: :all)
      end
    end

    it 'keeps showing the activities when another setting rebuilds the dashboard' do
      within '.sidebar' do
        expect(page).to have_text('Ticket of a colleague')
      end

      Setting.set('dashboard_first_steps', false)

      within :active_content do
        expect(page).to have_no_css('div.tab[data-area=first-steps-widgets]')
      end

      within '.sidebar' do
        expect(page).to have_text('Ticket of a colleague')
      end
    end
  end

  context 'when all listed activities drop out while the dashboard is open' do
    before do
      create(:ticket, group: Group.find_by(name: 'Users'), title: 'Ticket of a colleague')

      visit '/'
      wait_for_authenticated_session
    end

    it 'shows the description of the activity stream again' do
      within '.sidebar' do
        expect(page).to have_text('Ticket of a colleague')
        expect(page).to have_no_css('.activity-description')
      end

      # The backend pushes the emptied list only every 25 seconds, so it is sent from here.
      page.execute_script("App.Event.trigger('activity_stream_rebuild', { record_ids: [], assets: {} })")

      within '.sidebar' do
        expect(page).to have_no_text('Ticket of a colleague')
        expect(page).to have_css('.activity-description')
      end
    end
  end
end

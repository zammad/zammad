# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Ticket Priorities', type: :system do
  describe 'ajax pagination' do
    include_examples 'pagination', model: :ticket_priority, klass: Ticket::Priority, path: 'manage/ticket_priorities'
  end

  describe 'default create attribute' do
    before do
      priority
      old_priority if defined? old_priority

      visit 'manage/ticket_priorities'
    end

    context 'with existing default priority' do
      let(:priority) { Ticket::Priority.find_by(default_create: true) }

      it 'shows the badge next to the current default priority' do
        within :active_content do
          expect(find("tr[data-id='#{priority.id}']")).to have_css('span.badge', text: 'Default for new tickets')
        end
      end
    end

    context 'when using set as default action' do
      let(:priority)     { create(:ticket_priority, name: '4 very high') }
      let(:old_priority) { Ticket::Priority.find_by(default_create: true) }

      before do
        within :active_content do
          row = find("tr[data-id=\"#{priority.id}\"]")
          row.find('.js-action').click
          row.find('.js-setDefaultCreate').click
        end
      end

      it 'shows the badge next to the current default priority' do
        within :active_content do
          expect(find("tr[data-id='#{old_priority.id}']")).to have_no_css('span.badge', text: 'Default for new tickets')
          expect(find("tr[data-id='#{priority.id}']")).to have_css('span.badge', text: 'Default for new tickets')
        end
      end
    end
  end

  describe 'creating new priority' do
    let(:new_priority_name) { '4 very high' }

    before do
      visit 'manage/ticket_priorities'
      click_on 'New Priority'
    end

    it 'creates a new priority' do
      fill_in 'Name', with: new_priority_name

      scroll_into_view('button.js-submit', position: :bottom)
      click_on 'Submit'

      within :active_content do
        expect(find("tr[data-id='#{Ticket::Priority.last.id}']")).to have_text(new_priority_name)
      end
    end

    it 'does not show ui_icon field by default' do
      within :active_content do
        expect(page).to have_no_field('ui_icon')
      end
    end

    context 'with ui_ticket_priority_icons enabled', authenticated_as: :authenticate do
      def authenticate
        Setting.set('ui_ticket_priority_icons', true)
        true
      end

      it 'does not show ui_icon field by default' do
        within :active_content do
          expect(page).to have_no_field('ui_icon')
        end
      end

      it 'show ui_icon field when ui_color is set' do
        find('[name="ui_color"]').select('High priority')

        within :active_content do
          expect(page).to have_field('ui_icon')
        end
      end
    end
  end

  describe 'editing existing priority' do
    let(:priority)          { create(:ticket_priority, name: '4 very high', ui_color: 'high-priority', ui_icon: 'important') }
    let(:new_priority_name) { '5 highest' }

    before do
      priority
      visit 'manage/ticket_priorities'
      find("tr[data-id='#{priority.id}']").click
    end

    it 'edits existing priority' do
      fill_in 'Name', with: new_priority_name

      scroll_into_view('button.js-submit', position: :bottom)
      click_on 'Submit'

      within :active_content do
        expect(find("tr[data-id='#{priority.id}']")).to have_text(new_priority_name)
      end
    end

    it 'does not show ui_icon field by default' do
      within :active_content do
        expect(page).to have_no_field('ui_icon')
      end
    end

    context 'with ui_ticket_priority_icons enabled', authenticated_as: :authenticate do
      def authenticate
        Setting.set('ui_ticket_priority_icons', true)
        true
      end

      it 'shows ui_icon field with existing data' do
        within :active_content do
          expect(page).to have_select('ui_icon', selected: 'Important')
        end
      end
    end
  end
end

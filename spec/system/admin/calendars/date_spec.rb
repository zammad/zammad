require 'rails_helper'

RSpec.describe 'Admin Panel > Calendars date', type: :system, authenticated: true, time_zone: 'America/Sao_Paulo' do
  # https://github.com/zammad/zammad/issues/2229
  it 'Show festivities dates correctly far away from UTC' do
    visit '/#manage/calendars'

    click '.js-new'

    modal_ready

    within '.modal-dialog' do
      fill_in 'name', with: 'test calendar'

      click '.dropdown-toggle'
      click '.dropdown-menu [data-value="America/Sao_Paulo"]'

      find('.ical_feed select').select 'Brazil'

      click '.js-submit'
    end

    modal_disappear

    container = find('.action') { |elem| elem.find('.action-row h2').text == 'test calendar' }

    container.find('.js-edit').click

    modal_ready

    within '.modal-dialog' do
      scroll_to(css: '.modal-dialog', vertical: 'end')

      rows = find_all('.holiday_selector tr') { |elem| elem.has_css?('input.js-summary') && elem.find('input.js-summary').value.starts_with?('Christmas Eve') }
      row = rows[0]

      expect(row).to have_text('24')
      expect(row).to have_text('12')
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Calendars', type: :system do

  context 'Date' do
    let(:calendar_title) { "test calendar #{rand(999_999_999)}" }

    it 'show festivity dates correctly far away from UTC', time_zone: 'America/Sao_Paulo' do
      visit '/#manage/calendars'

      click '.js-new'

      modal_ready

      within '.modal-dialog' do
        fill_in 'name', with: calendar_title

        click '.dropdown-toggle'
        click '.dropdown-menu [data-value="America/Sao_Paulo"]'

        find('.ical_feed select').select 'Brazil'

        click '.js-submit'
      end

      modal_disappear

      within :active_content do
        within '.action', text: calendar_title do
          find('.js-edit').click
        end
      end

      wait(5).until_constant { find('.modal-dialog').style('height') }

      within '.modal-dialog' do
        row = first('.holiday_selector tr') do |elem|
          elem.find('input.js-summary').value.starts_with?('Christmas Eve')
        rescue
          false
        end

        expect(row).to have_text('24').and have_text('12')
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2528
  context 'ical feed - subscribe to public holidays in another country' do
    it 'shows countries dropdown in sorted order' do
      allow(Calendar).to receive(:ical_feeds).and_return({
                                                           'https://argentinien.de':  'Argentinien',
                                                           'https://australien.de':   'Australien',
                                                           'https://osterreich.de':   'Österreich',
                                                           'https://weibrussland.de': 'Weißrussland',
                                                           'https://kanada.de':       'Kanada',
                                                           'https://chile.de':        'Chile',
                                                         })

      visit '/#manage/calendars'

      click '.js-new'

      in_modal disappears: false do
        expect(all('.ical_feed select option').map(&:text)).to eq ['-', 'Argentinien', 'Australien', 'Chile', 'Kanada', 'Österreich', 'Weißrussland']
      end
    end
  end
end

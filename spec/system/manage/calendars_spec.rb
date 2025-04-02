# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Calendars', time_zone: 'America/Sao_Paulo', type: :system do

  context 'Date' do
    let(:calendar_title) { "test calendar #{SecureRandom.uuid}" }

    it 'show festivity dates correctly far away from UTC' do
      visit '/#manage/calendars'

      click '.js-new'

      in_modal do
        fill_in 'name', with: calendar_title

        click '.dropdown-toggle'
        click '.dropdown-menu [data-value="America/Sao_Paulo"]'

        find('.ical_feed select').select 'Brazil'

        click '.js-submit'
      end

      within :active_content do
        within '.action', text: calendar_title do
          find('.js-edit').click
        end
      end

      in_modal do
        # Check that holidays were imported by looking at the first entry.
        expect(find('.holiday_selector tbody tr:first-child td:nth-child(2)').text).to match(%r{^\d{4}-\d{2}-\d{2}$})
        expect(find('.holiday_selector tbody tr:first-child td input.js-summary').value).to be_present
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

      in_modal do
        expect(all('.ical_feed select option').map(&:text)).to eq ['-', 'Argentinien', 'Australien', 'Chile', 'Kanada', 'Österreich', 'Weißrussland']
      end
    end
  end
end

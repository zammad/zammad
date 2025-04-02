# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Translations', type: :system do

  before do
    visit '#system/translation'
  end

  context 'with description content' do
    context 'without any customized translations' do
      it 'shows description content on the page' do
        within :active_content do
          expect(page).to have_text('Contributing Translations')
            .and have_text('On-screen Translation')
        end
      end
    end

    context 'when there are customized translations present', authenticated_as: :authenticate do
      let(:translation) { create(:translation) }

      def authenticate
        translation
        true
      end

      it 'provides description button' do
        click_on 'Description'

        in_modal do
          expect(page).to have_text('Contributing Translations')
            .and have_text('On-screen Translation')
        end
      end
    end
  end

  context 'with overview table', authenticated_as: :authenticate do
    let(:translations) { create_list(:translation, 10) }

    def authenticate
      translations
      true
    end

    it 'shows all customized translations in the table' do
      within :active_content do
        expect(page).to have_text('TRANSLATION SOURCE')
          .and have_text('ORIGINAL TRANSLATION')
          .and have_text('CUSTOM TRANSLATION')
          .and have_text('TARGET LANGUAGE')
          .and have_text('ACTION')

        expect(find_all('tbody tr').length).to eq(10)

        translations.each do |translation|
          expect(page).to have_text(translation.source)
            .and have_text(translation.target_initial)
            .and have_text(translation.target)
            .and have_text(Locale.find_by(locale: translation.locale).name)
        end
      end
    end

    it 'provides remove action' do
      within :active_content do
        row = find("tr[data-id='#{translations[9].id}']")
        row.find('.js-action').click
        expect(row).to have_no_css('.js-reset')
        row.find('.js-remove').click
      end

      in_modal do
        click_on 'Yes'
      end

      within :active_content do
        expect(page).to have_no_text(translations[9].source)
      end
    end

    context 'with customized translation from codebase' do
      let(:translation) { Translation.last }

      def authenticate
        translation.update!(target: 'foobar')
        true
      end

      it 'provides reset action' do
        within :active_content do
          row = find("tr[data-id='#{translation.id}']")
          row.find('.js-action').click
          expect(row).to have_no_css('.js-remove')
          row.find('.js-reset').click
        end

        in_modal do
          click_on 'Yes'
        end

        within :active_content do
          expect(page).to have_no_text('foobar')
          expect(page).to have_text('Contributing Translations')
            .and have_text('On-screen Translation')
        end
      end
    end
  end

  context 'with translation management' do
    context 'with new customized translations' do
      before do
        click_on 'New Translation'
      end

      it 'adds new custom translation' do
        in_modal do
          set_textarea_field_value('source', 'foo')
          set_textarea_field_value('target', 'bar')
          click_on 'Submit'
        end

        within :active_content do
          expect(page).to have_text('foo')
            .and have_text('bar')
            .and have_text('English (United States)')
        end
      end

      it 'provides translation suggestions' do
        in_modal do
          expect(page).to have_text('TRANSLATION SOURCE')
            .and have_text('ORIGINAL TRANSLATION')
            .and have_text('TYPE')

          row = find_all('tbody tr')[0]

          source_text = row.find_all('td')[1].text
          target_text = row.find_all('td')[2].text

          row.find_all('td')[0].click

          check_textarea_field_value('source', source_text)
          find_field('target', placeholder: target_text)

          expect(page).to have_text('Did you know that system translations can be contributed and shared with the community on our public platform 🔗? It sports a very convenient user interface based on Weblate, give it a try!')
        end
      end

      it 'supports filtering translation suggestions' do
        in_modal do
          fill_in 'Search…', with: Translation.last.source
          expect(find('table')).to have_text(Translation.last.source)
        end
      end

      it 'refreshes list of suggestions when locale is changed' do
        in_modal do
          english_translation = Translation.find_by(locale: 'en-us')

          fill_in 'Search…', with: english_translation.source

          expect(find('table')).to have_text(english_translation.target_initial)

          set_tree_select_value('locale', 'Deutsch')

          german_translation = Translation.find_by(locale: 'de-de', source: english_translation.source)

          expect(find('table')).to have_no_text(english_translation.target_initial)
          expect(find('table')).to have_text(german_translation.target_initial)
        end
      end
    end

    context 'with existing customized translations', authenticated_as: :authenticate do
      let(:translation) { create(:translation) }

      def authenticate
        translation
        true
      end

      it 'allows selective editing' do
        within :active_content do
          row = find("tr[data-id='#{translation.id}']")
          row.find_all('td')[0].click
        end

        in_modal do
          find_field('source', disabled: true)
          set_textarea_field_value('target', 'foobar')
          find_field('locale', disabled: true, visible: :all)
          expect(page).to have_no_table
          click_on 'Submit'
        end

        within :active_content do
          expect(page).to have_text('foobar')
        end
      end
    end
  end
end

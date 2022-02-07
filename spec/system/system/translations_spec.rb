# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Translations', type: :system do
  prepend_before do
    Locale.where.not(locale: %w[en-us de-de]).destroy_all # remove all but 2 locales for quicker test
  end

  context 'when modifying strings locally', authenticated_as: :admin do

    shared_examples 'test local string modification' do |locale|
      let(:admin) { create(:admin, preferences: { locale: locale }) }

      it "allows translations to be changed locally for locale #{locale}" do

        visit '/#system/translation'
        field = find('.content.active input.js-Item[data-source="Translations"]')
        original_value = field.value
        field.fill_in(with: 'ModifiedString')
        field.native.send_keys :tab

        # Cause nav to re-render
        visit '/#dashboard'
        visit '/#system/translation'

        within :active_content do

          expect(find('.sidebar a[href="#system/translation"]').text).to eq('ModifiedString')
          find('input.js-Item[data-source="Translations"]').ancestor('tr').find('.js-Reset').click
          # Let find() wait for the field to be updated...
          expect(find("input.js-Item[data-source='Translations'][value='#{original_value}']").value).to eq(original_value)
          expect(find('.sidebar a[href="#system/translation"]').text).to eq('ModifiedString')
        end

        # Cause nav to re-render
        visit '/#dashboard'
        visit '/#system/translation'
        expect(find('.sidebar a[href="#system/translation"]').text).to eq(original_value)
      end
    end

    context 'for source locale' do
      let(:admin) { create(:admin, preferences: { locale: 'en-us' }) }

      include_examples 'test local string modification', 'en-us'
    end

    context 'for translated locale' do
      let(:admin) { create(:admin, preferences: { locale: 'de-de' }) }

      before do
        # Suppress the modal dialog that invites to contributions for translations that are < 95% as this breaks the tests for de-de.
        page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"
      end

      include_examples 'test local string modification', 'de-de'
    end
  end

  context 'when using inline translation', authenticated_as: :admin do
    shared_examples 'check inline translations' do |overviews_translated|
      it 'allows to use inline translations' do
        visit '/#system/translation'

        def toggle_inline_translations
          if Gem::Platform.local.os.eql? 'darwin'
            page.send_keys [:control, :alt, 't']
          else
            page.send_keys [:control, :shift, 't']
          end
        end

        toggle_inline_translations

        span = find '.sidebar span.translation[title="Overviews"]'
        # Move cursor to the end of the string.
        if Gem::Platform.local.os.eql? 'darwin'
          span.send_keys %i[command right], '_modified', :tab
        else
          span.send_keys %i[control right], '_modified', :tab
        end

        # Leave the span to be able to turn off inline translations again
        visit '/#dashboard'
        toggle_inline_translations

        visit '/#system/translation'
        expect(page).to have_no_css('.sidebar span.translation[title="Overviews"]')
        expect(find('a[href="#manage/overviews"]')).to have_text("#{overviews_translated}_modified")
        expect(find('.content.active input.js-Item[data-source="Overviews"]').value).to eq("#{overviews_translated}_modified")
      end
    end

    context 'for source locale' do
      let(:admin) { create(:admin, preferences: { locale: 'en-us' }) }

      include_examples 'check inline translations', 'Overviews'
    end

    context 'for translated locale' do
      let(:admin) { create(:admin, preferences: { locale: 'de-de' }) }

      before do
        # Suppress the modal dialog that invites to contributions for translations that are < 95% as this breaks the tests for de-de.
        page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"
      end

      include_examples 'check inline translations', 'Übersichten'
    end
  end

  context 'when showing a modal dialog that asks for help with translations', authenticated_as: :admin do

    let(:admin) { create(:admin, preferences: { locale: 'xy-zz' }) }

    it 'asks for help with very incomplete translations' do
      visit '/#system/translation'
      expect(page).to have_text('Only 0% of this language is already translated. Please help to improve Zammad and complete the translation.')
    end

    it 'asks to improve translations with solid coverage' do
      visit '/#system/translation'
      page.evaluate_script('App.i18n.meta = function(){ return { total: 100, translated: 89 } }')
      expect(page).to have_text('Up to 89% of this language is already translated. Please help to make Zammad even better and complete the translation.')
    end
  end

end

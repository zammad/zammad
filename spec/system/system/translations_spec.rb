# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Translations', type: :system do
  prepend_before do
    Locale.where.not(locale: %w[en-us de-de]).destroy_all # remove all but 2 locales for quicker test
  end

  it 'when clicking "Get latest translations" fetches all translations' do
    visit 'system/translation'

    allow(Translation).to receive(:load).with('de-de').and_return(true)
    allow(Translation).to receive(:load).with('en-us').and_return(true)

    click '.js-syncChanges'

    modal_disappear # make sure test is not terminated while modal is visible
  end

  # see https://github.com/zammad/zammad/issues/2056
  #
  # The purpose of this test is to verify that the Translation admin panel automatically re-renders under certain edge cases:
  #
  # Clicking into the Translation panel from another admin panel ALWAYS causes a rerender,
  # but clicking into it from, e.g., a Ticket or the Dashboard does not.
  #
  # We want to ensure that in the latter case, the Translation panel rerenders automatically if there are new phrases to translate.
  context "when missing translations are found in 'developer_mode'", authenticated_as: :admin_de do
    let(:admin_de) { create(:admin, preferences: { locale: 'de-de' }) }

    before do
      # developer_mode is required to track missing translations in the GUI.
      Setting.set('developer_mode', true)
    end

    it 're-renders the Translation admin panel correctly' do

      # The only way to test the edge case describe above
      # (i.e., visiting the Translation panel directly from a Ticket or the Dashboard)
      # is to first click into the admin settings and visit the Translation panel,
      # then leave, then come back.
      visit('/#system/translation')

      expect(page).to have_text('Inline Übersetzung')

      visit('/#dashboard')

      new_ui_phrase = 'Charlie bit me!'
      page.evaluate_script("App.i18n.translateContent('#{new_ui_phrase}')")

      visit('/#system/translation')
      expect(page).to have_text(new_ui_phrase)
    end
  end

  context 'when using the source locale', authenticated_as: :admin do
    let(:admin) { create(:admin, preferences: { locale: 'en-us' }) }

    it 'offers no translations to change' do
      visit '/#system/translation'
      expect(page).to have_text('English is the source language, so we have nothing to translate')
    end
  end

  context 'when using a translation locale', authenticated_as: :admin_de do
    let(:admin_de) { create(:admin, preferences: { locale: 'de-de' }) }

    it 'allows translations to be changed locally' do

      visit '/#system/translation'
      field = find('.content.active input.js-Item[data-source="Translations"]')
      field.fill_in(with: 'Übersetzung2')
      field.native.send_keys :tab

      # Cause nav to re-render
      visit '/#dashboard'
      visit '/#system/translation'

      within :active_content do

        expect(find('.sidebar a[href="#system/translation"]').text).to eq('Übersetzung2')
        find('input.js-Item[data-source="Translations"]').ancestor('tr').find('.js-Reset').click
        # Let find() wait for the field to be updated...
        expect(find('input.js-Item[data-source="Translations"][value="Übersetzung"]').value).to eq('Übersetzung')
        expect(find('.sidebar a[href="#system/translation"]').text).to eq('Übersetzung2')
      end

      # Cause nav to re-render
      visit '/#dashboard'
      visit '/#system/translation'
      expect(find('.sidebar a[href="#system/translation"]').text).to eq('Übersetzung')
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
      # This may seem unexpected: en-us currently offers inline translation changing,
      #   even though the System > Translations screen says "nothing to translate".

      include_examples 'check inline translations', 'Overviews'
    end

    context 'for translated locale' do
      let(:admin) { create(:admin, preferences: { locale: 'de-de' }) }

      include_examples 'check inline translations', 'Übersichten'
    end
  end
end

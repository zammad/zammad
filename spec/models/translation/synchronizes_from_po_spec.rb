# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Translation, 'synchronizes_from_po' do

  context 'when getting the list of files for a locale' do

    context 'when a locale is nonexistent' do
      it 'logs an error' do
        allow(Rails.logger).to receive(:error)
        described_class.po_files_for_locale('nonexisting-locale')
        expect(Rails.logger).to have_received(:error).with("No translation found for locale 'nonexisting-locale'.")
      end

      it 'returns an empty array' do
        expect(described_class.po_files_for_locale('nonexisting-locale')).to eq([])
      end
    end

    context 'when the locale is en-us' do
      it 'returns the translation source catalog' do
        expect(described_class.po_files_for_locale('en-us')).to eq(['i18n/zammad.pot'])
      end
    end

    context 'when getting the de-de file list' do
      before do
        # Simulate an addon translation file being present by duplicating zammad's de-de translation.
        FileUtils.copy(Rails.root.join('i18n/zammad.de-de.po'), Rails.root.join('i18n/testaddon.de-de.po'))
      end

      after do
        FileUtils.remove(Rails.root.join('i18n/testaddon.de-de.po'))
      end

      it 'has the framework content as first entry' do
        expect(described_class.po_files_for_locale('de-de').first).to eq('i18n/zammad.de-de.po')
      end

      it 'also has another addon translation file' do
        expect(described_class.po_files_for_locale('de-de')).to include('i18n/testaddon.de-de.po')
      end
    end

    context 'when getting the sr-latn-rs file list' do
      it 'uses the sr-cyrl-rs framework content instead' do
        expect(described_class.po_files_for_locale('sr-latn-rs').first).to eq('i18n/zammad.sr-cyrl-rs.po')
      end
    end
  end

  context 'when getting po strings for a locale' do
    context 'when getting strings for a nonexistent locale' do
      it 'logs an error' do
        allow(Rails.logger).to receive(:error)
        described_class.strings_for_locale('nonexisting-locale')
        expect(Rails.logger).to have_received(:error).with("No translation found for locale 'nonexisting-locale'.")
      end

      it 'returns an empty array' do
        expect(described_class.strings_for_locale('nonexisting-locale')).to eq({})
      end
    end

    context 'when getting the en-us strings' do
      it 'contains the translation for "yes"' do
        expect(described_class.strings_for_locale('en-us')['yes']).to have_attributes(translation: 'yes', translation_file: 'i18n/zammad.pot')
      end

      it 'contains the translation for "FORMAT_DATE"' do
        expect(described_class.strings_for_locale('en-us')['FORMAT_DATE']).to have_attributes(translation: 'mm/dd/yyyy', translation_file: 'i18n/zammad.pot')
      end

      it 'contains the translation for "FORMAT_DATE_TIME"' do
        expect(described_class.strings_for_locale('en-us')['FORMAT_DATETIME']).to have_attributes(translation: 'mm/dd/yyyy l:MM P', translation_file: 'i18n/zammad.pot')
      end
    end

    context 'when getting the de-de strings' do
      it 'contains the translation for "yes"' do
        expect(described_class.strings_for_locale('de-de')['yes']).to have_attributes(translation: 'ja', translation_file: 'i18n/zammad.de-de.po')
      end

      it 'contains the translation for "FORMAT_DATE"' do
        expect(described_class.strings_for_locale('de-de')['FORMAT_DATE']).to have_attributes(translation: 'dd.mm.yyyy', translation_file: 'i18n/zammad.de-de.po')
      end

      it 'contains the translation for "FORMAT_DATE_TIME"' do
        expect(described_class.strings_for_locale('de-de')['FORMAT_DATETIME']).to have_attributes(translation: 'dd.mm.yyyy HH:MM', translation_file: 'i18n/zammad.de-de.po')
      end
    end

    context 'when getting the sr-latn-rs strings' do
      it 'contains transliterated sr-cyrl-rs translation for "yes"' do
        expect(described_class.strings_for_locale('sr-latn-rs')['yes']).to have_attributes(translation: 'da', translation_file: 'i18n/zammad.sr-cyrl-rs.po')
      end
    end
  end

  context 'when unescaping po strings' do
    it 'does the right thing' do
      expect(Translation::TranslationEntry.unescape_po('My complex \\n \\" string \\\\ with quotes')).to eq("My complex \n \" string \\ with quotes")
    end
  end

  context 'when synchronizing strings for a locale' do
    let(:translation_after_sync) do
      test_translation = described_class.find_source('de-de', translation_before_sync[:source]) || described_class.new
      test_translation.update(translation_before_sync.merge(locale: 'de-de', created_by_id: 1, updated_by_id: 1))
      described_class.sync_locale_from_po('de-de')
      described_class.find_by(id: test_translation.id)
    end

    context 'when unknown user strings are present' do
      let(:translation_before_sync) { { source: 'unknown string', target: 'unknown translation', is_synchronized_from_codebase: false, synchronized_from_translation_file: nil } }

      it 'leaves them alone' do
        expect(translation_after_sync).to have_attributes(translation_before_sync)
      end
    end

    context 'when unknown, but user modified synchronized strings are present' do
      let(:translation_before_sync) { { source: 'unknown string', target_initial: 'unknown translation', target: 'user modified', is_synchronized_from_codebase: true, synchronized_from_translation_file: nil } }

      it 'leaves them alone' do
        expect(translation_after_sync).to have_attributes(translation_before_sync)
      end
    end

    context 'when unknown & unchanged synchronized strings are present' do
      let(:translation_before_sync) { { source: 'unknown string', target: 'unknown translation', is_synchronized_from_codebase: true } }

      it 'deletes them' do
        expect(translation_after_sync).to be_nil
      end
    end

    context 'when existing synchronized strings need an update' do
      context 'when unmodified' do
        let(:translation_before_sync) { { source: 'yes', target_initial: 'unknown translation', target: 'unknown translation', is_synchronized_from_codebase: true } }

        it 'updates both target and target_initial' do
          expect(translation_after_sync).to have_attributes(target_initial: 'ja', target: 'ja')
        end
      end

      context 'when modified' do
        let(:translation_before_sync) { { source: 'yes', target_initial: 'unknown translation', target: 'user changed', is_synchronized_from_codebase: true } }

        it 'updates only target_initial' do
          expect(translation_after_sync).to have_attributes(target_initial: 'ja', target: 'user changed')
        end
      end

      context 'when source language file changes' do
        let(:translation_before_sync) { { source: 'yes', synchronized_from_translation_file: 'i18n/my-fabulous-addon.de-de.po', is_synchronized_from_codebase: true } }

        it 'updates :synchronized_from_translation_file' do
          expect(translation_after_sync).to have_attributes(synchronized_from_translation_file: 'i18n/zammad.de-de.po')
        end
      end
    end

    context 'when existing unsynchronized strings start to be synchronized' do
      context 'when unmodified' do
        let(:translation_before_sync) { { source: 'yes', target_initial: 'user changed', target: 'user changed', is_synchronized_from_codebase: false } }

        it 'updates both target and target_initial' do
          expect(translation_after_sync).to have_attributes(target_initial: 'ja', target: 'ja', is_synchronized_from_codebase: true)
        end
      end

      context 'when modified' do
        let(:translation_before_sync) { { source: 'yes', target_initial: 'user changed', target: 'different', is_synchronized_from_codebase: false } }

        it 'updates only target_initial' do
          expect(translation_after_sync).to have_attributes(target_initial: 'ja', target: 'different', is_synchronized_from_codebase: true)
        end
      end
    end

    context 'when new strings are added via sync' do
      before do
        described_class.find_source('de-de', 'yes').destroy!
        described_class.sync_locale_from_po('de-de')
      end

      it 'adds them' do
        expect(described_class.find_source('de-de', 'yes')).to have_attributes(source: 'yes', target_initial: 'ja', target: 'ja', is_synchronized_from_codebase: true, synchronized_from_translation_file: 'i18n/zammad.de-de.po')
      end
    end
  end

  context 'when synchronizing strings for CI locales' do

    # Tests are slow, so use before :all to save time.
    before :all do # rubocop:disable RSpec/BeforeAfterAll
      # Simulate additional entries
      Rails.root.join('i18n/testaddon.de-de.po').write(<<~CUSTOM_PO)
        #: app/graphql/custom.rb
        msgid "custom-string-translated"
        msgstr "custom-string-übersetzt"

        #: app/views/mailer/ticket_create/zh-tw.html.erb
        #: app/views/slack/ticket_create/en.md.erb
        msgid "custom-string-to-skip"
        msgstr "custom-string-zu-überspringen"

        msgid "custom-string-too-long"
        msgstr "custom-string-too-long #{'a' * 3001}"

        msgid "custom-string-untranslated"
        msgstr ""

        #, fuzzy
        msgid "custom-string-fuzzy"
        msgstr "custom-string-fuzzy"

      CUSTOM_PO

      described_class.all.delete_all
      described_class.sync
    end

    after :all do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.remove(Rails.root.join('i18n/testaddon.de-de.po'))
    end

    it 'adds many of them' do
      expect(described_class.where(locale: 'de-de').count).to be > 500
    end

    it 'adds correct data' do
      expect(described_class.where(locale: 'de-de').first).to have_attributes(is_synchronized_from_codebase: true, synchronized_from_translation_file: 'i18n/zammad.de-de.po')
    end

    it 'adds the en-us FORMAT_DATE entry' do
      expect(described_class.find_source('en-us', 'FORMAT_DATE')).to have_attributes(is_synchronized_from_codebase: true, synchronized_from_translation_file: 'i18n/zammad.pot', target: 'mm/dd/yyyy')
    end

    it 'adds the en-us FORMAT_DATETIME entry' do
      expect(described_class.find_source('en-us', 'FORMAT_DATETIME')).to have_attributes(is_synchronized_from_codebase: true, synchronized_from_translation_file: 'i18n/zammad.pot', target: 'mm/dd/yyyy l:MM P')
    end

    it 'adds the custom translated entry with content' do
      expect(described_class.find_source('de-de', 'custom-string-translated')).to have_attributes(target: 'custom-string-übersetzt')
    end

    it 'adds the custom untranslated entry without content' do
      expect(described_class.find_source('de-de', 'custom-string-untranslated')).to have_attributes(target: '')
    end

    it 'adds the custom fuzzy entry without content' do
      expect(described_class.find_source('de-de', 'custom-string-fuzzy')).to have_attributes(target: '')
    end

    it 'ignores strings that are too long' do
      expect(described_class.find_source('de-de', 'custom-string-too-long')).to be_nil
    end

    it 'skips strings that need to be skipped' do
      expect(described_class.find_source('de-de', 'custom-string-to-skip')).to be_nil
    end
  end

  # Make sure that translation imports work really for some major locales.
  context 'when synchronizing strings for some major locales' do
    before do
      # Only 'en-us' and 'de-de' are returned in test env - override.
      allow(Locale).to receive(:to_sync).and_return(Locale.where(locale: %w[en-us de-de fr-fr ru zh-cn]))
      described_class.sync
    end

    it 'imports without error and finds Chinese entries' do
      expect(described_class.where(locale: 'zh-cn').count).to be > 500
    end
  end

end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Host spec must provide, within a 'basic Knowledge Base' context:
#   let!(:record)         - a persisted described_class with a single translation in `primary_locale`
#   let(:add_translation) - a callable creating and returning a translation of `record` in a locale
RSpec.shared_examples 'HasTranslations' do
  describe '.preferred_translations_for' do
    let(:pair) { [record.id, requested_locale.id] }

    context 'when translated in the requested locale' do
      let(:requested_locale) { primary_locale }

      it 'returns that translation' do
        expect(described_class.preferred_translations_for([pair]))
          .to eq(pair => record.translation_preferred(primary_locale))
      end
    end

    context 'when not translated in the requested locale' do
      let(:requested_locale) { alternative_locale }

      it 'falls back to the primary translation' do
        expect(described_class.preferred_translations_for([pair]))
          .to eq(pair => record.translation_preferred(primary_locale))
      end

      context 'when later translated there' do
        let!(:alternative_translation) { add_translation.call(alternative_locale) }

        it 'prefers the requested-locale translation' do
          expect(described_class.preferred_translations_for([pair]))
            .to eq(pair => alternative_translation)
        end
      end
    end

    it 'maps a pair whose record has no translation to nil' do
      expect(described_class.preferred_translations_for([[0, primary_locale.id]]))
        .to eq([0, primary_locale.id] => nil)
    end

    it 'returns an empty hash when given no pairs' do
      expect(described_class.preferred_translations_for([])).to eq({})
    end
  end

  describe '.translated_to_system_locale' do
    it 'includes a record translated to the locale' do
      expect(described_class.translated_to_system_locale(primary_locale.system_locale)).to include(record)
    end

    it 'takes the id of the locale as well' do
      expect(described_class.translated_to_system_locale(primary_locale.system_locale_id)).to include(record)
    end

    it 'leaves out a record not translated to the locale' do
      expect(described_class.translated_to_system_locale(alternative_locale.system_locale)).not_to include(record)
    end

    it 'includes the record once translated there' do
      add_translation.call(alternative_locale)

      expect(described_class.translated_to_system_locale(alternative_locale.system_locale)).to include(record)
    end

    it 'matches nothing without a locale' do
      expect(described_class.translated_to_system_locale(nil)).not_to exist
    end

    # KnowledgeBase.available_in and KnowledgeBase::Category.available_in `.or` it with their content
    #   check, which a join on either side would make structurally incompatible.
    it 'composes with .or' do
      expect(described_class.translated_to_system_locale(alternative_locale.system_locale).or(described_class.where(id: record.id)))
        .to include(record)
    end
  end

  describe '.with_preferred_translation' do
    let(:other_locale) { create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'de-de')) }

    def loaded_translation
      described_class.with_preferred_translation(alternative_locale.system_locale).find(record.id).translation
    end

    it 'loads the translation in the requested locale' do
      alternative_translation = add_translation.call(alternative_locale)

      expect(loaded_translation).to eq(alternative_translation)
    end

    it 'falls back to the primary translation' do
      add_translation.call(other_locale)

      expect(loaded_translation.kb_locale).to eq(primary_locale)
    end

    it 'falls back to any translation where there is no primary one' do
      record.translations.destroy_all
      add_translation.call(other_locale)

      expect(loaded_translation.kb_locale).to eq(other_locale)
    end

    # `#translation` is `translations.first`, so the fallback only holds while nothing else is loaded
    #   alongside it.
    it 'loads that one translation only' do
      add_translation.call(other_locale)

      expect(described_class.with_preferred_translation(alternative_locale.system_locale).find(record.id).translations.size).to eq(1)
    end

    it 'leaves out a record with no translation at all' do
      record.translations.destroy_all

      expect(described_class.with_preferred_translation(alternative_locale.system_locale)).not_to exist(record.id)
    end
  end
end

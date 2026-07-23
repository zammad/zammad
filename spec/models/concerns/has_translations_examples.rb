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
end

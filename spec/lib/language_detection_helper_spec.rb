# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe LanguageDetectionHelper do
  describe '#detect' do
    it 'does detect german languages' do
      expect(described_class.detect('Entdecken Sie jetzt das Zammad Ticketsystem!'))
        .to eq('de')
    end

    it 'does not return the language if response was flagged as unreliable' do
      allow(CLD)
        .to receive(:detect_language)
        .and_return({ reliable: false, code: 'en' })

      expect(described_class.detect('Entdecken Sie jetzt das Zammad Ticketsystem!'))
        .to be_blank
    end

    it 'does not return if language is unknown' do
      allow(CLD)
        .to receive(:detect_language)
        .and_return({ reliable: true, code: 'un' })

      expect(described_class.detect('Entdecken Sie jetzt das Zammad Ticketsystem!'))
        .to be_blank
    end
  end

  describe '#display_value' do
    it 'returns the language name' do
      expect(described_class.display_value('de')).to eq('German')
    end

    it 'does not return if language is unknown' do
      expect(described_class.display_value('xx')).to be_nil
    end
  end
end

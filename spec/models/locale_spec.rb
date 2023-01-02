# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Locale, type: :model do
  describe 'Class methods:' do
    describe '.default' do
      context 'with default locale' do
        before { Setting.set('locale_default', 'foo') }

        it 'returns the system-wide default locale' do
          expect(described_class.default).to eq('foo')
        end
      end

      context 'without default locale' do
        before { Setting.set('locale_default', nil) }

        it 'returns en-us' do
          expect(described_class.default).to eq('en-us')
        end
      end
    end

    describe '.sync()' do
      context 'when importing locales' do
        before do
          described_class.all.delete_all
          described_class.sync
        end

        it 'imports many locales locales' do
          expect(described_class.count).to be > 40
        end

        it 'imports locale data correctly' do
          expect(described_class.find_by(locale: 'de-de')).to have_attributes(locale: 'de-de', alias: 'de', name: 'Deutsch', dir: 'ltr', active: true)
        end
      end
    end
  end
end

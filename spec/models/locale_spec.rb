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
  end
end

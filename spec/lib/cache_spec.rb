require 'rails_helper'

RSpec.describe Cache do
  describe '.get' do
    before { allow(Rails.cache).to receive(:read) }

    it 'wraps Rails.cache.read' do
      described_class.get('foo')

      expect(Rails.cache).to have_received(:read).with('foo')
    end

    context 'with a non-string argument' do
      it 'passes a string' do
        described_class.get(:foo)

        expect(Rails.cache).to have_received(:read).with('foo')
      end
    end
  end

  describe '.write' do
    it 'stores string values' do
      expect { described_class.write('123', 'some value') }
        .to change { described_class.get('123') }.to('some value')
    end

    it 'stores hash values' do
      expect { described_class.write('123', { key: 'some value' }) }
        .to change { described_class.get('123') }.to({ key: 'some value' })
    end

    it 'overwrites previous values' do
      described_class.write('123', 'some value')

      expect { described_class.write('123', { key: 'some value' }) }
        .to change { described_class.get('123') }.to({ key: 'some value' })
    end

    it 'stores hash values with non-ASCII content' do
      expect { described_class.write('123', { key: 'some valueöäüß' }) }
        .to change { described_class.get('123') }.to({ key: 'some valueöäüß' })
    end

    context 'when expiring' do

      # we need to travel to a fixed point in time
      # to prevent influences of timezone / DST
      before do
        travel_to '1995-12-21 13:37 +0100'
      end

      it 'defaults to expires_in: 7.days' do
        described_class.write('123', 'some value')

        expect { travel 7.days - 1.second }.not_to change { described_class.get('123') }
        expect { travel 2.seconds }.to change { described_class.get('123') }.to(nil)
      end

      it 'accepts a custom :expires_in option' do
        described_class.write('123', 'some value', expires_in: 3.seconds)

        expect { travel 4.seconds }.to change { described_class.get('123') }.to(nil)
      end
    end
  end

  describe '.delete' do
    it 'deletes stored values' do
      described_class.write('123', 'some value')

      expect { described_class.delete('123') }
        .to change { described_class.get('123') }.to(nil)
    end

    it 'is idempotent' do
      described_class.write('123', 'some value')
      described_class.delete('123')

      expect { described_class.delete('123') }.not_to raise_error
    end
  end

  describe '.clear' do
    it 'deletes all stored values' do
      described_class.write('123', 'some value')
      described_class.write('456', 'some value')

      expect { described_class.clear }
        .to change { described_class.get('123') }.to(nil)
        .and change { described_class.get('456') }.to(nil)
    end

    it 'is idempotent' do
      described_class.write('123', 'some value')
      described_class.clear

      expect { described_class.clear }.not_to raise_error
    end

    context 'when cache directory is not present on disk' do
      before { FileUtils.rm_rf(Rails.cache.cache_path) }

      it 'does not raise an error' do
        expect { described_class.clear }.not_to raise_error
      end
    end
  end
end

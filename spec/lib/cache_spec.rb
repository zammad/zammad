require 'rails_helper'

RSpec.describe Cache do
  describe '.get' do
    before { allow(Rails.cache).to receive(:read) }

    it 'wraps Rails.cache.read' do
      Cache.get('foo')

      expect(Rails.cache).to have_received(:read).with('foo')
    end

    context 'with a non-string argument' do
      it 'passes a string' do
        Cache.get(:foo)

        expect(Rails.cache).to have_received(:read).with('foo')
      end
    end
  end

  describe '.write' do
    it 'stores string values' do
      expect { Cache.write('123', 'some value') }
        .to change { Cache.get('123') }.to('some value')
    end

    it 'stores hash values' do
      expect { Cache.write('123', { key: 'some value' }) }
        .to change { Cache.get('123') }.to({ key: 'some value' })
    end

    it 'overwrites previous values' do
      Cache.write('123', 'some value')

      expect { Cache.write('123', { key: 'some value' }) }
        .to change { Cache.get('123') }.to({ key: 'some value' })
    end

    it 'stores hash values with non-ASCII content' do
      expect { Cache.write('123', { key: 'some valueöäüß' }) }
        .to change { Cache.get('123') }.to({ key: 'some valueöäüß' })
    end

    it 'defaults to expires_in: 7.days' do
      Cache.write('123', 'some value')

      expect { travel 7.days }.not_to change { Cache.get('123') }
      expect { travel 1.second }.to change { Cache.get('123') }.to(nil)
    end

    it 'accepts a custom :expires_in option' do
      Cache.write('123', 'some value', expires_in: 3.seconds)

      expect { travel 4.seconds }.to change { Cache.get('123') }.to(nil)
    end
  end

  describe '.delete' do
    it 'deletes stored values' do
      Cache.write('123', 'some value')

      expect { Cache.delete('123') }
        .to change { Cache.get('123') }.to(nil)
    end

    it 'is idempotent' do
      Cache.write('123', 'some value')
      Cache.delete('123')

      expect { Cache.delete('123') }.not_to raise_error
    end
  end

  describe '.clear' do
    it 'deletes all stored values' do
      Cache.write('123', 'some value')
      Cache.write('456', 'some value')

      # rubocop:disable Layout/MultilineMethodCallIndentation
      expect { Cache.clear }
        .to change { Cache.get('123') }.to(nil)
        .and change { Cache.get('456') }.to(nil)
      # rubocop:enable Layout/MultilineMethodCallIndentation
    end

    it 'is idempotent' do
      Cache.write('123', 'some value')
      Cache.clear

      expect { Cache.delete('123') }.not_to raise_error
    end
  end
end

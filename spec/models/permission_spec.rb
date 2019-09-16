require 'rails_helper'

RSpec.describe Permission, type: :model do
  describe '.with_parents' do
    context 'when given a simple string (no dots)' do
      it 'returns an array containing only that string' do
        expect(described_class.with_parents('foo')).to eq(['foo'])
      end
    end

    context 'when given a String permission name (dot-delimited identifier)' do
      it 'returns an array of String ancestors (desc. from root)' do
        expect(described_class.with_parents('foo.bar.baz'))
          .to eq(%w[foo foo.bar foo.bar.baz])
      end
    end
  end
end

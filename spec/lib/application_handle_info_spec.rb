require 'rails_helper'

RSpec.describe ApplicationHandleInfo do
  describe '.use' do
    it 'requires a block' do
      expect { described_class.use('foo') }
        .to raise_error(ArgumentError)
    end

    context 'for a given starting ApplicationHandleInfo' do
      before { described_class.current = 'foo' }

      it 'runs the block using the given ApplicationHandleInfo' do
        described_class.use('bar') do
          expect(described_class.current).to eq('bar')
        end
      end

      it 'resets ApplicationHandleInfo to its original value' do
        described_class.use('bar') {}

        expect(described_class.current).to eq('foo')
      end

      context 'when an error is raised in the given block' do
        it 'does not rescue the error, and still resets ApplicationHandleInfo' do
          expect { described_class.use('bar') { raise } }
            .to raise_error(StandardError)
            .and not_change { described_class.current }
        end
      end
    end
  end
end

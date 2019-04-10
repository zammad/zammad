require 'rails_helper'

RSpec.describe ApplicationHandleInfo do
  describe '.use' do
    it 'requires a block' do
      expect { ApplicationHandleInfo.use('foo') }
        .to raise_error(ArgumentError)
    end

    context 'for a given starting ApplicationHandleInfo' do
      before { ApplicationHandleInfo.current = 'foo' }

      it 'runs the block using the given ApplicationHandleInfo' do
        ApplicationHandleInfo.use('bar') do
          expect(ApplicationHandleInfo.current).to eq('bar')
        end
      end

      it 'resets ApplicationHandleInfo to its original value' do
        ApplicationHandleInfo.use('bar') {}

        expect(ApplicationHandleInfo.current).to eq('foo')
      end

      context 'when an error is raised in the given block' do
        it 'does not rescue the error, and still resets ApplicationHandleInfo' do
          expect { ApplicationHandleInfo.use('bar') { raise } }
            .to raise_error(StandardError)
            .and not_change { ApplicationHandleInfo.current }
        end
      end
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationHandleInfo do
  describe '.use' do
    it 'requires a block' do
      expect { described_class.use('foo') }
        .to raise_error(ArgumentError)
    end

    context 'for a given starting ApplicationHandleInfo' do
      # This `around` block is identical to ApplicationHandleInfo.use.
      #
      # Q: So why don't we just use it here to DRY things up?
      # A: Because that's the method we're trying to test, dummy!
      #
      # Q: Why can't we do `before { ApplicationHandleInfo.current = 'foo' }` instead?
      # A: Because that would change `ApplicationHandleInfo.current` for all subsequent specs.
      #    (RSpec uses database transactions to keep test environments clean,
      #    but `ApplicationHandleInfo.current` lives outside of the database.)
      around do |example|
        original = described_class.current
        described_class.current = 'foo'
        example.run
        described_class.current = original
      end

      it 'runs the block using the given ApplicationHandleInfo' do
        described_class.use('bar') do
          expect(described_class.current).to eq('bar')
        end
      end

      it 'resets ApplicationHandleInfo to its original value' do
        described_class.use('bar') { nil }

        expect(described_class.current).to eq('foo')
      end

      context 'when an error is raised in the given block' do
        it 'does not rescue the error, and still resets ApplicationHandleInfo' do
          expect { described_class.use('bar') { raise } }
            .to raise_error(StandardError)
            .and not_change(described_class, :current)
        end
      end
    end
  end
end

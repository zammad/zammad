# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationHandleInfo do
  shared_context 'safe block execution' do |attribute:|
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
      original = described_class.send(attribute)
      described_class.send("#{attribute}=", 'foo')
      example.run
      described_class.send("#{attribute}=", original)
    end
  end

  describe '.use' do
    it 'requires a block' do
      expect { described_class.use('foo') }
        .to raise_error(ArgumentError)
    end

    context 'for a given starting ApplicationHandleInfo' do
      include_examples 'safe block execution', attribute: :current

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

  describe '.in_context' do
    it 'requires a block' do
      expect { described_class.use('foo') }
        .to raise_error(ArgumentError)
    end

    context 'for a given starting ApplicationHandleInfo' do
      include_examples 'safe block execution', attribute: :context

      it 'runs the block using the given ApplicationHandleInfo' do
        described_class.in_context('bar') do
          expect(described_class.context).to eq('bar')
        end
      end

      it 'resets ApplicationHandleInfo to its original value' do
        described_class.in_context('bar') { nil }

        expect(described_class.context).to eq('foo')
      end

      context 'when an error is raised in the given block' do
        it 'does not rescue the error, and still resets ApplicationHandleInfo' do
          expect { described_class.in_context('bar') { raise } }
            .to raise_error(StandardError)
            .and not_change(described_class, :context)
        end
      end
    end
  end

  describe '.context_without_custom_attributes?' do
    it 'returns false when set to default context' do
      expect(described_class).not_to be_context_without_custom_attributes
    end

    context 'for a given starting ApplicationHandleInfo' do
      include_examples 'safe block execution', attribute: :context

      it 'returns true when set to context that does not use custom attributes' do
        described_class.context = 'merge'
        expect(described_class).to be_context_without_custom_attributes
      end

      it 'returns true when in .in_context block' do
        described_class.in_context(:merge) do
          expect(described_class).to be_context_without_custom_attributes
        end
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::EmailRecipientNormalizer do
  describe '.normalize' do
    before do
      create(
        :user,
        firstname: 'Max',
        lastname:  'Mustermann',
        email:     'max@example.com'
      )
    end

    it 'returns nil unchanged' do
      expect(described_class.normalize(nil)).to be_nil
    end

    it 'returns empty string unchanged' do
      expect(described_class.normalize('')).to eq('')
    end

    it 'returns known user as recipient line' do
      expect(described_class.normalize('max@example.com')).to eq('Max Mustermann <max@example.com>')
    end

    it 'normalizes known user email case-insensitively' do
      expect(described_class.normalize('MAX@EXAMPLE.COM')).to eq('Max Mustermann <max@example.com>')
    end

    it 'keeps unknown email as lowercase email' do
      expect(described_class.normalize('Unknown@Example.com')).to eq('unknown@example.com')
    end

    it 'keeps display name for unknown email' do
      input = 'Test User <Unknown@Example.com>'

      expect(described_class.normalize(input)).to eq('Test User <unknown@example.com>')
    end

    it 'prefers known user over provided display name' do
      input = 'Someone Else <max@example.com>'

      expect(described_class.normalize(input)).to eq('Max Mustermann <max@example.com>')
    end

    it 'does not modify non-email values like Users' do
      expect(described_class.normalize('Users')).to eq('Users')
    end

    it 'deduplicates identical emails case-insensitively' do
      input = 'MAX@example.com, max@example.com'

      expect(described_class.normalize(input)).to eq('Max Mustermann <max@example.com>')
    end

    it 'deduplicates identical unknown emails case-insensitively' do
      input = 'Unknown@Example.com, unknown@example.com'

      expect(described_class.normalize(input)).to eq('unknown@example.com')
    end

    it 'keeps unique recipients in order' do
      input = 'max@example.com, Other User <other@example.com>, Users'

      expect(described_class.normalize(input)).to eq(
        'Max Mustermann <max@example.com>, Other User <other@example.com>, Users'
      )
    end

    it 'returns original input when address parsing fails' do
      input = 'Max Mustermann <broken'

      expect(described_class.normalize(input)).to eq(input)
    end

    it 'returns original input if user preloading raises unexpectedly' do
      allow(User).to receive(:where).and_raise(StandardError, 'boom')

      input = 'max@example.com'

      expect(described_class.normalize(input)).to eq(input)
    end
  end
end

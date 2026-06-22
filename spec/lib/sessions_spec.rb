# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions do
  describe '.valid_client_id?' do
    it 'accepts a standard UUID' do
      expect(described_class.valid_client_id?(SecureRandom.uuid)).to be(true)
    end

    it 'accepts hex-only string' do
      expect(described_class.valid_client_id?('abc123def456')).to be(true)
    end

    it 'accepts numeric object_id style string' do
      expect(described_class.valid_client_id?('123456')).to be(true)
    end

    it 'rejects path traversal sequences' do
      expect(described_class.valid_client_id?('../etc/passwd')).to be(false)
    end

    it 'rejects dot-dot at start' do
      expect(described_class.valid_client_id?('..')).to be(false)
    end

    it 'rejects slashes' do
      expect(described_class.valid_client_id?('foo/bar')).to be(false)
    end

    it 'rejects backslashes' do
      expect(described_class.valid_client_id?('foo\\bar')).to be(false)
    end

    it 'rejects null bytes' do
      expect(described_class.valid_client_id?("abc\x00def")).to be(false)
    end

    it 'rejects empty string' do
      expect(described_class.valid_client_id?('')).to be(false)
    end

    it 'rejects nil' do
      expect(described_class.valid_client_id?(nil)).to be(false)
    end

    it 'rejects asterisk' do
      expect(described_class.valid_client_id?('*')).to be(false)
    end

    it 'rejects square brackets' do
      expect(described_class.valid_client_id?('test[0]')).to be(false)
    end

    it 'rejects question mark' do
      expect(described_class.valid_client_id?('test?')).to be(false)
    end

    it 'rejects uppercase letters' do
      expect(described_class.valid_client_id?('ABC123')).to be(false)
    end

    it 'rejects spaces' do
      expect(described_class.valid_client_id?('abc 123')).to be(false)
    end

    it 'rejects underscores' do
      expect(described_class.valid_client_id?('customer_session_id')).to be(false)
    end
  end

  describe '.get' do
    it 'returns nil for invalid client_id' do
      expect(described_class.get('../malicious')).to be_nil
    end
  end

  describe '.destroy' do
    it 'returns nil for invalid client_id' do
      expect(described_class.destroy('../malicious')).to be_nil
    end
  end

  describe '.create' do
    it 'returns nil for invalid client_id' do
      expect(described_class.create('../malicious', {}, { type: 'ajax' })).to be_nil
    end
  end

  describe '.touch' do
    it 'returns false for invalid client_id' do
      expect(described_class.touch('../malicious')).to be(false)
    end
  end

  describe '.send' do
    it 'returns false for invalid client_id' do
      expect(described_class.send(:'../malicious', { event: 'test' })).to be(false)
    end
  end

  describe '.queue' do
    it 'returns empty array for invalid client_id' do
      expect(described_class.queue('../malicious')).to eq([])
    end
  end
end

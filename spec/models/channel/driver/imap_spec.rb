# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Imap do
  # https://github.com/zammad/zammad/issues/2964
  context 'when connecting with a ASCII 8-Bit password' do
    it 'succeeds' do

      required_envs = %w[IMAP_ASCII_8BIT_HOST IMAP_ASCII_8BIT_USER IMAP_ASCII_8BIT_PASSWORD]
      required_envs.each do |key|
        next if ENV[key].present?

        skip("Need ENVs #{required_envs.join(', ')}.")
      end

      params = {
        host:     ENV['IMAP_ASCII_8BIT_HOST'],
        user:     ENV['IMAP_ASCII_8BIT_USER'],
        password: ENV['IMAP_ASCII_8BIT_PASSWORD'],
      }

      result = described_class.new.fetch(params, nil, 'check')

      expect(result[:result]).to eq 'ok'
    end
  end

  describe '.parse_rfc822_headers' do
    it 'parses simple header' do
      expect(described_class.parse_rfc822_headers('Key: Value')).to have_key('Key').and(have_value('Value'))
    end

    it 'parses header with no white space' do
      expect(described_class.parse_rfc822_headers('Key:Value')).to have_key('Key').and(have_value('Value'))
    end

    it 'parses multiline header' do
      expect(described_class.parse_rfc822_headers("Key: Value\r\n2nd-key: 2nd-value"))
        .to have_key('Key').and(have_value('Value')).and(have_key('2nd-key')).and(have_value('2nd-value'))
    end

    it 'parses value with semicolons' do
      expect(described_class.parse_rfc822_headers('Key: Val:ue')).to have_key('Key').and(have_value('Val:ue'))
    end

    it 'parses key-only lines' do
      expect(described_class.parse_rfc822_headers('Key')).to have_key('Key')
    end

    it 'handles empty line' do
      expect { described_class.parse_rfc822_headers("Key: Value\r\n") }.not_to raise_error
    end

    it 'handles tabbed value' do
      expect(described_class.parse_rfc822_headers("Key: \r\n\tValue")).to have_key('Key').and(have_value('Value'))
    end
  end

  describe '.extract_rfc822_headers' do
    it 'extracts header' do
      object = Net::IMAP::FetchData.new :id, { 'RFC822.HEADER' => 'Key: Value' }
      expect(described_class.extract_rfc822_headers(object)).to have_key('Key').and(have_value('Value'))
    end

    it 'returns nil when header attribute is missing' do
      object = Net::IMAP::FetchData.new :id, { 'Another' => 'Key: Value' }
      expect(described_class.extract_rfc822_headers(object)).to be_nil
    end

    it 'does not raise error when given nil' do
      expect { described_class.extract_rfc822_headers(nil) }.not_to raise_error
    end
  end
end

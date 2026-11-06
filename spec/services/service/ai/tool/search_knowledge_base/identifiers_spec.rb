# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::SearchKnowledgeBase::Identifiers, :aggregate_failures do
  describe '.in' do
    it 'finds error codes, versions, joined codes and order numbers, in the order of the query' do
      expect(described_class.in('Outlook error 0x8004010F after v2.1.3')).to eq(%w[0x8004010F v2.1.3])
      expect(described_class.in('SSL_ERROR_SYSCALL on ERR-4032 for order 1005678')).to eq(%w[SSL_ERROR_SYSCALL ERR-4032 1005678])
    end

    it 'keeps an identifier whole instead of the number inside it' do
      expect(described_class.in('incident INC-2041')).to eq(%w[INC-2041])
    end

    it 'leaves out plain and hyphenated words, short numbers and years' do
      expect(described_class.in('VPN full-page e-mail sync fails 42 since 2026')).to be_empty
    end

    it 'takes no parts joined by a slash, which the keyword search would read as a regular expression' do
      expect(described_class.in('order 2024/123456')).to eq(%w[123456])
    end

    it 'names each identifier once and three at most' do
      expect(described_class.in('E1001 e1001 E1002 E1003 E1004')).to eq(%w[E1001 E1002 E1003])
    end
  end
end

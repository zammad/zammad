# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::ArticleCustomerFactory do
  describe '.skip?' do
    let(:record) { { 'SenderType' => 'customer', 'CreatedBy' => '1', 'From' => 'customer@example.com' } }

    it 'imports customer articles created by the system user with a sender' do
      expect(described_class.skip?(record)).to be false
    end

    it 'supports the legacy CreateBy key' do
      expect(described_class.skip?(record.except('CreatedBy').merge('CreateBy' => '1'))).to be false
    end

    it 'skips articles not sent by a customer' do
      expect(described_class.skip?(record.merge('SenderType' => 'agent'))).to be true
    end

    it 'skips articles created by another user' do
      expect(described_class.skip?(record.merge('CreatedBy' => '2'))).to be true
    end

    it 'skips articles without a sender' do
      expect(described_class.skip?(record.merge('From' => ''))).to be true
    end
  end

  describe '.import' do
    let(:customer_record) { { 'SenderType' => 'customer', 'CreatedBy' => '1', 'From' => 'customer@example.com' } }
    let(:records) do
      [
        customer_record,
        customer_record.merge('SenderType' => 'agent'),
        customer_record.merge('CreatedBy' => '2'),
        customer_record.merge('From' => ''),
      ]
    end

    before do
      allow(Import::OTRS::ArticleCustomer).to receive(:new)
    end

    it 'imports only the articles of customers' do
      described_class.import(records)

      expect(Import::OTRS::ArticleCustomer).to have_received(:new).once.with(customer_record)
    end
  end
end

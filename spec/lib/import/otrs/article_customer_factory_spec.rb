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
      pending 'skip? is defined as an instance method, so the import always uses Import::BaseFactory.skip?'

      expect(described_class.skip?(record.merge('SenderType' => 'agent'))).to be true
    end

    it 'skips articles created by another user' do
      pending 'skip? is defined as an instance method, so the import always uses Import::BaseFactory.skip?'

      expect(described_class.skip?(record.merge('CreatedBy' => '2'))).to be true
    end

    it 'skips articles without a sender' do
      pending 'skip? is defined as an instance method, so the import always uses Import::BaseFactory.skip?'

      expect(described_class.skip?(record.merge('From' => ''))).to be true
    end
  end
end

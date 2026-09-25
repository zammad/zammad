# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::StoreValue::UnknownCustomer, type: :model do
  describe '.wrap' do
    it 'wraps a phone number' do
      expect(described_class.wrap('+49 30 609812345')).to eq({ 'phone' => '+49 30 609812345' })
    end

    it 'wraps an email address' do
      expect(described_class.wrap('new@example.com')).to eq({ 'email' => 'new@example.com' })
    end

    it 'leaves an id alone' do
      expect(described_class.wrap(2)).to eq(2)
    end

    it 'leaves a blank value alone' do
      expect(described_class.wrap('')).to eq('')
    end
  end

  describe '.unwrap' do
    it 'returns the wrapped number' do
      expect(described_class.unwrap({ 'phone' => '123456' })).to eq('123456')
    end

    it 'returns the wrapped address, whichever key type it comes with' do
      expect(described_class.unwrap({ email: 'new@example.com' })).to eq('new@example.com')
    end

    it 'returns nothing for an id, as an integer or the string the old UI writes' do
      expect([described_class.unwrap(2), described_class.unwrap('2')]).to all(be_nil)
    end
  end

  describe 'storing the taskbar state' do
    def store(field, value)
      FormUpdater::StoreValue.new(nil).perform(field:, value:)
    end

    it 'wraps a typed-in customer' do
      expect(store('customer_id', '123456')).to eq({ 'customer_id' => { 'phone' => '123456' } })
    end

    it 'keeps a known customer as the id' do
      expect(store('customer_id', 2)).to eq({ 'customer_id' => 2 })
    end

    it 'keeps a cleared customer blank' do
      expect(store('customer_id', '')).to eq({ 'customer_id' => '' })
    end

    it 'leaves other user fields alone' do
      expect(store('owner_id', '2')).to eq({ 'owner_id' => '2' })
    end
  end
end

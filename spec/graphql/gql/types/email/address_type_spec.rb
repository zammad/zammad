# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::Email::AddressType do
  let(:email)    { 'test@zammad.org' }
  let(:instance) { described_class.send(:new, { email_address: email, name: 'test' }, nil) }

  context 'when added as system email' do
    before do
      create(:email_address, email: email)
    end

    it 'is system address' do
      expect(instance.is_system_address).to be_truthy
    end
  end

  context 'when not added as system email' do
    it 'not system address' do
      expect(instance.is_system_address).not_to be_truthy
    end
  end
end

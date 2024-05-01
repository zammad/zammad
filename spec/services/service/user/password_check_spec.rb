# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordCheck do
  subject(:service) { described_class.new(user:, password:) }

  let(:user) { create(:agent, password: 'lorem') }

  context 'with empty password' do
    let(:password) { nil }

    it 'returns false' do
      expect(service.execute).to be_falsey
    end
  end

  context 'with wrong password' do
    let(:password) { 'nah' }

    it 'returns false' do
      expect(service.execute).to be_falsey
    end
  end

  context 'with correct password' do
    let(:password) { 'lorem' }

    it 'returns true' do
      expect(service.execute).to be_truthy
    end
  end
end

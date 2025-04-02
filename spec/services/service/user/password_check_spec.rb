# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordCheck do
  subject(:service) { described_class.new(user:, password:) }

  let(:user) { create(:agent, password: 'lorem') }

  context 'with empty password' do
    let(:password) { nil }

    it 'returns false for success and does not include token' do
      expect(service.execute).to include(success: false).and(not_include(:token))
    end
  end

  context 'with wrong password' do
    let(:password) { 'nah' }

    it 'returns false for success and does not include token' do
      expect(service.execute).to include(success: false).and(not_include(:token))
    end
  end

  context 'with correct password' do
    let(:password) { 'lorem' }

    it 'returns true for success and includes a token' do
      expect(service.execute).to include(success: true, token: be_a(String))
    end
  end
end

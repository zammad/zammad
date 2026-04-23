# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordCheck do
  let(:user) { create(:agent, password: 'lorem') }

  context 'with empty password' do
    subject(:service_result) { described_class.with_current_user(user).execute(password: nil) }

    it 'returns false for success and does not include token' do
      expect(service_result).to include(success: false).and(not_include(:token))
    end
  end

  context 'with wrong password' do
    subject(:service_result) { described_class.with_current_user(user).execute(password: 'nah') }

    it 'returns false for success and does not include token' do
      expect(service_result).to include(success: false).and(not_include(:token))
    end
  end

  context 'with correct password' do
    subject(:service_result) { described_class.with_current_user(user).execute(password: 'lorem') }

    it 'returns true for success and includes a token' do
      expect(service_result).to include(success: true, token: be_a(String))
    end
  end
end

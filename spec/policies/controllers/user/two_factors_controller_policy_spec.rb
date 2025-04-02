# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::User::TwoFactorsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { User::TwoFactorsController }
  let(:record)       { record_class.new }
  let(:user)         { create(:agent) }

  let(:actions) do
    %i[
      enabled_authentication_methods personal_configuration authentication_method_initiate_configuration authentication_method_configuration
      verify_configuration default_authentication_method recovery_codes_generate
      remove_authentication_method authentication_remove_credentials
    ]
  end

  context 'when user has 2FA permission' do
    it { is_expected.to permit_actions(actions) }
  end

  context 'when user does not have 2FA permission' do
    before do
      user
        .roles
        .first
        .permission_revoke 'user_preferences.two_factor_authentication'
    end

    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(actions) }
  end
end

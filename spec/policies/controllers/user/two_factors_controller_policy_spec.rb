# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::User::TwoFactorsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { User::TwoFactorsController }
  let(:record) do
    rec             = record_class.new
    rec.params      = params

    rec
  end

  let(:twofactoree) { create(:agent) }

  describe 'endpoints for current user' do
    let(:user)   { twofactoree }
    let(:params) { {} }

    it { is_expected.to permit_actions(:two_factor_verify_configuration, :two_factor_authentication_method_configuration) }
  end

  describe 'endpoints allowing to manage other users' do
    let(:params) { { id: twofactoree.id } }

    context 'with an admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_actions(:two_factor_enabled_authentication_methods, :two_factor_remove_authentication_method, :two_factor_remove_all_authentication_methods) }
    end

    context 'with a different user' do
      let(:user) { create(:agent) }

      it { is_expected.to forbid_actions(:two_factor_enabled_authentication_methods, :two_factor_remove_authentication_method, :two_factor_remove_all_authentication_methods) }
    end

    context 'with the user' do
      let(:user) { twofactoree }

      it { is_expected.to permit_actions(:two_factor_enabled_authentication_methods, :two_factor_remove_authentication_method, :two_factor_remove_all_authentication_methods) }
    end
  end
end

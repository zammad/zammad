# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

    let(:permitted_actions) do
      %i[two_factor_verify_configuration two_factor_authentication_method_initiate_configuration two_factor_default_authentication_method two_factor_authentication_method_configuration two_factor_authentication_method_configuration_save]
    end

    it { is_expected.to permit_actions(permitted_actions) }
  end

  describe 'endpoints allowing to manage other users' do
    let(:params) { { id: twofactoree.id } }

    context 'with an admin' do
      let(:user) { create(:admin) }
      let(:permitted_actions) do
        %i[two_factor_enabled_authentication_methods two_factor_remove_authentication_method two_factor_remove_all_authentication_methods]
      end

      it { is_expected.to permit_actions(permitted_actions) }
    end

    context 'with a different user' do
      let(:user) { create(:agent) }
      let(:forbidden_actions) do
        %i[two_factor_enabled_authentication_methods two_factor_remove_authentication_method two_factor_remove_all_authentication_methods]
      end

      it { is_expected.to forbid_actions(forbidden_actions) }
    end

    context 'with the user' do
      let(:user) { twofactoree }
      let(:permitted_actions) do
        %i[two_factor_enabled_authentication_methods two_factor_remove_authentication_method two_factor_remove_all_authentication_methods]
      end

      it { is_expected.to permit_actions(permitted_actions) }
    end
  end
end

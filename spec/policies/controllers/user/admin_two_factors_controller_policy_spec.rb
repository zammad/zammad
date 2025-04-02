# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::User::AdminTwoFactorsControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { User::AdminTwoFactorsController }
  let(:record)       { record_class.new.tap { _1.params = { id: 123 } } }

  let(:agent) { create(:agent) }

  let(:actions) do
    %i[remove_authentication_method remove_all_authentication_methods enabled_authentication_methods]
  end

  context 'with an admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(actions) }
  end

  context 'with a different user' do
    let(:user) { agent }

    it { is_expected.to forbid_actions(actions) }
  end
end

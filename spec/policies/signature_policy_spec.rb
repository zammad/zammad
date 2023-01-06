# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe SignaturePolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:signature) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_actions(:show) }
    it { is_expected.to forbid_actions(:create, :update, :destroy) }

    context 'when signature is inactive' do
      let(:record) { create(:signature, active: false) }

      it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end
end

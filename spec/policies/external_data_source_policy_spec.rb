# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe ExternalDataSourcePolicy do
  subject { described_class.new(user, record) }

  context 'when attribute type is Group' do
    let(:record) { 'Group' }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is agent' do
      let(:user) { create(:agent) }

      it { is_expected.to forbid_action(:fetch) }
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it { is_expected.to forbid_action(:fetch) }
    end
  end

  context 'when attribute type is Organization' do
    let(:record) { 'Organization' }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is agent' do
      let(:user) { create(:agent) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it { is_expected.to forbid_action(:fetch) }
    end
  end

  context 'when attribute type is User' do
    let(:record) { 'User' }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is agent' do
      let(:user) { create(:agent) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it { is_expected.to forbid_action(:fetch) }
    end
  end

  context 'when attribute type is Ticket' do
    let(:record) { 'Ticket' }

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is agent' do
      let(:user) { create(:agent) }

      it { is_expected.to permit_action(:fetch) }
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it { is_expected.to permit_action(:fetch) }
    end
  end
end

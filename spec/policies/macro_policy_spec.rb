# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe MacroPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:macro, groups:) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    context 'when macro is not active' do
      before { record.update! active: false }

      let(:groups) { [] }

      it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
    end

    context 'when macro has group user does not have access to' do
      let(:groups) { [create(:group)] }

      it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
    end
  end

  context 'when user is agent' do
    let(:group) { create(:group) }
    let(:user)  { create(:agent, groups: [group]) }

    context 'when macro has no group' do
      let(:groups) { [] }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_actions(:create, :update, :destroy) }

      context 'when macro is not active' do
        before { record.update! active: false }

        it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
      end
    end

    context 'when macro has group user has access to' do
      let(:groups) { [group, create(:group)] }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_actions(:create, :update, :destroy) }

      context 'when macro is not active' do
        before { record.update! active: false }

        it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
      end
    end

    context 'when macro has group user no access to' do
      let(:groups) { [create(:group)] }

      it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
    end

    context "when macro has group user has 'read' access to" do
      context 'when roles are used' do
        let(:groups) do
          group = create(:group)

          role = create(:role, :agent)
          role.group_ids_access_map = { group.id => 'read' }
          role.save!

          user.roles = [role]
          user.save!

          [group]
        end

        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_actions(:create, :update, :destroy) }
      end

      context 'when groups are used' do
        let(:groups) do
          group = create(:group)

          user.group_ids_access_map = { group.id => 'read' }
          user.save!

          [group]
        end

        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_actions(:create, :update, :destroy) }
      end
    end
  end

  context 'when user is customer' do
    let(:user)   { create(:customer) }
    let(:groups) { [] }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
  end
end

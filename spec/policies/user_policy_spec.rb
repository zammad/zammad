# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

describe UserPolicy do
  subject { described_class.new(user, record) }

  context 'when user is an admin' do
    let(:user) { create(:user, roles: [partial_admin_role]) }

    context 'with "admin.user" privileges' do
      let(:partial_admin_role) do
        create(:role).tap { |role| role.permission_grant('admin.user') }
      end

      context 'wants to read, change, or delete any user' do

        context 'when record is an admin user' do
          let(:record) { create(:admin) }

          it { is_expected.to permit_actions(%i[show update destroy]) }
        end

        context 'when record is an agent user' do
          let(:record) { create(:agent) }

          it { is_expected.to permit_actions(%i[show update destroy]) }
        end

        context 'when record is a customer user' do
          let(:record) { create(:customer) }

          it { is_expected.to permit_actions(%i[show update destroy]) }
        end

        context 'when record is any user' do
          let(:record) { create(:user) }

          it { is_expected.to permit_actions(%i[show update destroy]) }
        end

        context 'when record is the same user' do
          let(:record) { user }

          it { is_expected.to permit_actions(%i[show update destroy]) }
        end
      end
    end

    context 'without "admin.user" privileges' do
      let(:partial_admin_role) do
        create(:role).tap { |role| role.permission_grant('admin.tag') }
      end

      context 'when record is an admin user' do
        let(:record) { create(:admin) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_actions(%i[update destroy]) }
      end

      context 'when record is an agent user' do
        let(:record) { create(:agent) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_actions(%i[update destroy]) }
      end

      context 'when record is a customer user' do
        let(:record) { create(:customer) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_actions(%i[update destroy]) }
      end

      context 'when record is any user' do
        let(:record) { create(:user) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_actions(%i[update destroy]) }
      end

      context 'when record is the same user' do
        let(:record) { user }

        it { is_expected.to permit_action(:show) }
        it { is_expected.not_to permit_actions(%i[update destroy]) }
      end
    end
  end

  context 'when user is an agent' do
    let(:user) { create(:agent) }

    context 'when record is an admin user' do
      let(:record) { create(:admin) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_actions(%i[update destroy]) }
    end

    context 'when record is an agent user' do
      let(:record) { create(:agent) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_actions(%i[update destroy]) }
    end

    context 'when record is a customer user' do
      let(:record) { create(:customer) }

      it { is_expected.to permit_actions(%i[show update]) }
      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'when record is any user' do
      let(:record) { create(:user) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_actions(%i[update destroy]) }
    end

    context 'when record is the same user' do
      let(:record) { user }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_actions(%i[update destroy]) }
    end
  end

  context 'when user is a customer' do
    let(:user) { create(:customer) }

    context 'when record is an admin user' do
      let(:record) { create(:admin) }

      it { is_expected.not_to permit_actions(%i[show update destroy]) }
    end

    context 'when record is an agent user' do
      let(:record) { create(:agent) }

      it { is_expected.not_to permit_actions(%i[show update destroy]) }
    end

    context 'when record is a customer user' do
      let(:record) { create(:customer) }

      it { is_expected.not_to permit_actions(%i[show update destroy]) }
    end

    context 'when record is any user' do
      let(:record) { create(:user) }

      it { is_expected.not_to permit_actions(%i[show update destroy]) }
    end

    context 'when record is a colleague' do
      let(:user) { create(:customer, :with_org) }
      let(:record) { create(:customer, organization: user.organization) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_actions(%i[update destroy]) }
    end

    context 'when record is the same user' do
      let(:record) { user }

      it { is_expected.to permit_action(:show) }
      it { is_expected.not_to permit_actions(%i[update destroy]) }
    end
  end
end

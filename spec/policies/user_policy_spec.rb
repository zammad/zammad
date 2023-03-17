# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe UserPolicy do
  subject(:user_policy) { described_class.new(user, record) }

  context 'when user is an admin' do
    let(:user) { create(:user, roles: [partial_admin_role]) }

    context 'with "admin.user" privileges' do
      let(:partial_admin_role) do
        create(:role).tap { |role| role.permission_grant('admin.user') }
      end

      context 'wants to read, change, or delete any user' do

        context 'when record is an admin user' do
          let(:record) { create(:admin) }

          it { is_expected.to permit_actions(%i[show nested_show update destroy]) }
        end

        context 'when record is an agent user' do
          let(:record) { create(:agent) }

          it { is_expected.to permit_actions(%i[show nested_show update destroy]) }
        end

        context 'when record is a customer user' do
          let(:record) { create(:customer) }

          it { is_expected.to permit_actions(%i[show nested_show update destroy]) }
        end

        context 'when record is any user' do
          let(:record) { create(:user) }

          it { is_expected.to permit_actions(%i[show nested_show update destroy]) }
        end

        context 'when record is the same user' do
          let(:record) { user }

          it { is_expected.to permit_actions(%i[show nested_show update destroy]) }
        end
      end
    end

    context 'without "admin.user" privileges' do
      let(:partial_admin_role) do
        create(:role).tap { |role| role.permission_grant('admin.tag') }
      end

      context 'when record is an admin user' do
        let(:record) { create(:admin) }

        it { is_expected.to permit_actions(%i[show nested_show]) }
        it { is_expected.to forbid_actions(%i[update destroy]) }
      end

      context 'when record is an agent user' do
        let(:record) { create(:agent) }

        it { is_expected.to permit_actions(%i[show nested_show]) }
        it { is_expected.to forbid_actions(%i[update destroy]) }
      end

      context 'when record is a customer user' do
        let(:record) { create(:customer) }

        it { is_expected.to permit_actions(%i[show nested_show]) }
        it { is_expected.to forbid_actions(%i[update destroy]) }
      end

      context 'when record is any user' do
        let(:record) { create(:user) }

        it { is_expected.to permit_actions(%i[show nested_show]) }
        it { is_expected.to forbid_actions(%i[update destroy]) }
      end

      context 'when record is the same user' do
        let(:record) { user }

        it { is_expected.to permit_actions(%i[show nested_show]) }
        it { is_expected.to forbid_actions(%i[update destroy]) }
      end
    end
  end

  context 'when user is an agent' do
    let(:user) { create(:agent) }

    context 'when record is an admin user' do
      let(:record) { create(:admin) }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end

    context 'when record is an agent user' do
      let(:record) { create(:agent) }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end

    context 'when record is a customer user' do
      let(:record) { create(:customer) }

      it { is_expected.to permit_actions(%i[show update]) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context 'when record is any user' do
      let(:record) { create(:user) }

      it { is_expected.to permit_actions(%i[show nested_show update]) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context 'when record is the same user' do
      let(:record) { user }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end

    context 'when record is both admin and customer' do
      let(:record) { create(:customer, role_ids: Role.signup_role_ids.push(Role.find_by(name: 'Admin').id)) }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end

    context 'when record is both agent and customer' do
      let(:record) { create(:customer, role_ids: Role.signup_role_ids.push(Role.find_by(name: 'Agent').id)) }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end

  end

  context 'when user is a customer' do
    let(:user) { create(:customer) }

    shared_examples 'restricts fields' do |method|
      it "restricts fields for #{method}", :aggregate_failures do
        expect(user_policy.public_send(method)).to permit_fields(%i[id firstname lastname image image_source active])
        expect(user_policy.public_send(method)).to forbid_fields(%i[email phone mobile note])
      end
    end

    shared_examples 'does not restrict fields' do |method|
      it "does not restrict fields for #{method}" do
        expect(user_policy.public_send(method)).to be(true)
      end
    end

    context 'when record is an admin user' do
      let(:record) { create(:admin) }

      it { is_expected.to permit_actions(%i[nested_show]) }
      it { is_expected.to forbid_actions(%i[show update destroy]) }

      include_examples 'restricts fields', :nested_show?
    end

    context 'when record is an agent user' do
      let(:record) { create(:agent) }

      it { is_expected.to permit_actions(%i[nested_show]) }
      it { is_expected.to forbid_actions(%i[show update destroy]) }

      include_examples 'restricts fields', :nested_show?
    end

    context 'when record is a customer user' do
      let(:record) { create(:customer) }

      it { is_expected.to permit_actions(%i[nested_show]) }
      it { is_expected.to forbid_actions(%i[show update destroy]) }

      include_examples 'restricts fields', :nested_show?
    end

    context 'when record is any user' do
      let(:record) { create(:user) }

      it { is_expected.to permit_actions(%i[nested_show]) }
      it { is_expected.to forbid_actions(%i[show update destroy]) }

      include_examples 'restricts fields', :nested_show?
    end

    context 'when record is a colleague' do
      let(:user)   { create(:customer, :with_org) }
      let(:record) { create(:customer, organization: user.organization) }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }

      include_examples 'restricts fields', :nested_show?
      include_examples 'restricts fields', :show?
    end

    context 'when record is the same user' do
      let(:record) { user }

      it { is_expected.to permit_actions(%i[show nested_show]) }
      it { is_expected.to forbid_actions(%i[update destroy]) }

      include_examples 'does not restrict fields', :nested_show?
      include_examples 'does not restrict fields', :show?
    end

    context 'when record is both admin and customer' do
      let(:record) { create(:customer, role_ids: Role.signup_role_ids.push(Role.find_by(name: 'Admin').id)) }

      it { is_expected.to permit_action(:nested_show) }
      it { is_expected.to forbid_actions(%i[show update destroy]) }

      include_examples 'restricts fields', :nested_show?
    end

    context 'when record is both agent and customer' do
      let(:record) { create(:customer, role_ids: Role.signup_role_ids.push(Role.find_by(name: 'Agent').id)) }

      it { is_expected.to permit_action(:nested_show) }
      it { is_expected.to forbid_actions(%i[show update destroy]) }

      include_examples 'restricts fields', :nested_show?
    end

  end
end

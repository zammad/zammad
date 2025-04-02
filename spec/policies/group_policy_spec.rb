# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe GroupPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:group) }

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show) }
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    context 'when user has access to group' do
      before do
        user.groups << record
        user.group_names_access_map = { record.name => permissions }
      end

      context 'with full access' do
        let(:permissions) { ['full'] }

        it { is_expected.to permit_actions(:show) }
      end

      context 'with read access' do
        let(:permissions) { ['read'] }

        it { is_expected.to permit_actions(:show) }
      end

      context 'with create access' do
        let(:permissions) { ['create'] }

        it { is_expected.to permit_actions(:show) }
      end

      context 'with change access' do
        let(:permissions) { ['change'] }

        it { is_expected.to permit_actions(:show) }
      end

      context 'with overview access' do
        let(:permissions) { ['overview'] }

        it { is_expected.to forbid_actions(:show) }
      end
    end

    context 'when user does not have access to group' do
      it { is_expected.to forbid_actions(:show) }
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    shared_examples 'restricts fields' do |method|
      it "restricts fields for #{method}", :aggregate_failures do
        expect(subject.public_send(method)).to permit_fields(%i[id name follow_up_possible reopen_time_in_days active])
        expect(subject.public_send(method)).to forbid_fields(%i[email_address signature note])
      end
    end

    context 'when has ticket in group' do
      before { create(:ticket, group: record, customer: user) }

      it { is_expected.to permit_actions(:show) }

      include_examples 'restricts fields', :show?
    end

    context 'when group is in customer_ticket_create_group_ids' do
      before do
        Setting.set('customer_ticket_create_group_ids', [record.id])
      end

      it { is_expected.to permit_actions(:show) }

      include_examples 'restricts fields', :show?
    end

    context 'when customer_ticket_create_group_ids is empty and thus all groups are permitted' do
      before do
        Setting.set('customer_ticket_create_group_ids', [])
      end

      it { is_expected.to permit_actions(:show) }

      include_examples 'restricts fields', :show?
    end

    context 'when group is not in customer_ticket_create_group_ids' do
      before do
        Setting.set('customer_ticket_create_group_ids', [record.id + 1])
      end

      context 'when has no ticket in a group' do
        it { is_expected.to forbid_actions(:show) }
      end
    end
  end
end

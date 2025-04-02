# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe RolePolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:role) }

  shared_examples 'restricts fields' do |method|
    it "restricts fields for #{method}", :aggregate_failures do
      expect(subject.public_send(method)).to permit_fields(%i[id groups permissions active])
      expect(subject.public_send(method)).to forbid_fields(%i[name])
    end
  end

  shared_examples 'does not restrict fields' do |method|
    it "does not restrict fields for #{method}" do
      expect(subject.public_send(method)).to be(true)
    end
  end

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show) }

    include_examples 'does not restrict fields', :show?
  end

  context 'when user is agent' do
    let(:user) { create(:agent) }

    context 'when user has access to role' do
      before { user.roles << record }

      it { is_expected.to permit_actions(:show) }

      include_examples 'does not restrict fields', :show?
    end

    context 'when user does not have access to role' do
      it { is_expected.to forbid_actions(:show) }
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    context 'when user has access to role' do
      before { user.roles << record }

      it { is_expected.to permit_actions(:show) }

      include_examples 'restricts fields', :show?
    end

    context 'when user does not have access to role' do
      it { is_expected.to forbid_actions(:show) }
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe OrganizationPolicy do
  subject(:organization_policy) { described_class.new(user, record) }

  let(:record) { create(:organization) }

  shared_examples 'restricts fields' do |method|
    it "restricts fields for #{method}", :aggregate_failures do
      expect(organization_policy.public_send(method)).to permit_fields(%i[id name active])
      expect(organization_policy.public_send(method)).to forbid_fields(%i[shared domain note])
    end
  end

  context 'when user is a customer in the same organization' do
    let(:user) { create(:customer, organization: record) }

    it { is_expected.to permit_actions(%i[show]) }
    it { is_expected.to forbid_actions(%i[update]) }

    include_examples 'restricts fields', :show?
  end

  context 'when user is a customer without organization' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(%i[show update]) }
  end

  context 'when user is an agent and customer' do
    let(:user) { create(:agent_and_customer, organization: record) }

    it { is_expected.to permit_actions(%i[show update]) }
  end

  context 'when user is an agent' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_actions(%i[show update]) }
  end

  context 'when user is an admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(%i[show update]) }
  end
end

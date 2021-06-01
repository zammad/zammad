# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

describe OrganizationPolicy do
  subject { described_class.new(user, record) }

  let(:record) { create(:organization) }

  context 'when customer' do
    let(:user) { create(:customer, organization: record) }

    it { is_expected.to permit_actions(%i[show]) }
    it { is_expected.not_to permit_actions(%i[update]) }
  end

  context 'when customer without organization' do
    let(:user) { create(:customer) }

    it { is_expected.not_to permit_actions(%i[show update]) }
  end

  context 'when agent and customer' do
    let(:user) { create(:agent_and_customer, organization: record) }

    it { is_expected.to permit_actions(%i[show update]) }
  end

  context 'when agent' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_actions(%i[show update]) }
  end

  context 'when admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(%i[show update]) }
  end
end

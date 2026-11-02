# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketPolicy::BaseScope do
  subject(:scope) { described_class.new(user) }

  describe '#resolve' do
    context 'when querying for agent user' do
      let(:user) { create(:agent) }

      it 'raises NoMethodError (undefined on abstract base class)' do
        expect { scope.resolve }.to raise_error(NoMethodError)
      end
    end

    context 'when querying for customer user' do
      let(:user) { create(:customer) }

      it 'raises NoMethodError (undefined on abstract base class)' do
        expect { scope.resolve }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#shared_organization_ids' do
    let(:shared_organization)           { create(:organization, shared: true) }
    let(:secondary_shared_organization) { create(:organization, shared: true) }
    let(:organizations)                 { [secondary_shared_organization, create(:organization, shared: false)] }

    context 'with a customer' do
      let(:user) { create(:customer, organization: shared_organization, organizations:) }

      it 'returns the shared primary and secondary organizations' do
        expect(scope.shared_organization_ids).to contain_exactly(shared_organization.id, secondary_shared_organization.id)
      end
    end

    context 'with an agent' do
      let(:user) { create(:agent, organization: shared_organization, organizations:) }

      it 'returns no organizations' do
        expect(scope.shared_organization_ids).to be_empty
      end
    end
  end
end

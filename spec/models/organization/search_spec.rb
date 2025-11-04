# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Organization::Search do
  describe 'access check' do
    let(:organization_1) { create(:organization, name: 'search 1') }
    let(:organization_2) { create(:organization, name: 'search 2', shared: false) }
    let(:organization_3) { create(:organization, name: 'search 3') }
    let(:organization_4) { create(:organization, name: 'search 4', shared: false) }
    let(:customer)       { create(:customer, organization: organization_1, organizations: [organization_2]) }

    before do
      organization_1 && organization_2 && organization_3 && organization_4 && customer
    end

    shared_examples 'search for organizations' do
      let(:results) { Organization.search(current_user: user, query: 'search') }

      context 'when user is agent' do
        let(:user) { create(:agent) }

        it 'finds accessible organizations' do
          expect(results).to contain_exactly(organization_1, organization_2, organization_3, organization_4)
        end
      end

      context 'when user is customer' do
        let(:user) { customer }

        it 'finds accessible organizations' do
          expect(results).to contain_exactly(organization_1, organization_2)
        end
      end
    end

    context 'with elasticsearch', searchindex: true do
      before do
        searchindex_model_reload([Organization])
      end

      include_examples 'search for organizations'
    end

    context 'with db only' do
      include_examples 'search for organizations'
    end
  end
end

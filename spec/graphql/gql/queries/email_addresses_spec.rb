# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::EmailAddresses, type: :graphql do

  context 'when fetching EmailAddresses' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query emailAddresses($onlyActive: Boolean = false) {
          emailAddresses(onlyActive: $onlyActive) {
            name
            email
            active
          }
        }
      QUERY
    end
    let(:variables) { { onlyActive: false } }
    let(:email_address) { create(:email_address) }

    before do
      email_address.update_columns(active: false)
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to eq([{ 'name' => email_address.name, 'email' => email_address.email, 'active' => false }])
      end

      context 'when fetching only active addresses' do
        let(:variables) do
          { onlyActive: true }
        end

        it 'does not include inactive addresses' do
          expect(gql.result.data).to eq([])
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end

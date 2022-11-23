# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::Recipient, authenticated_as: :agent, type: :graphql do

  context 'when searching for recipients' do
    let(:agent)     { create(:agent) }
    let(:recipient) { create(:customer) }
    let(:query)     do
      <<~QUERY
        query autocompleteSearchRecipient($input: AutocompleteSearchInput!)  {
          autocompleteSearchRecipient(input: $input) {
            value
            label
            labelPlaceholder
            heading
            headingPlaceholder
            disabled
            icon
          }
        }
      QUERY
    end
    let(:variables) { { input: { query: query_string, limit: nil } } }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with exact search' do
      let(:recipient_payload) do
        {
          'value'              => recipient.email,
          'label'              => "#{recipient.fullname} <#{recipient.email}>",
          'labelPlaceholder'   => nil,
          'heading'            => nil,
          'headingPlaceholder' => nil,
          'icon'               => nil,
          'disabled'           => nil,
        }
      end
      let(:query_string) { recipient.email }

      it 'has email as value and heading' do
        expect(gql.result.data).to eq([recipient_payload])
      end
    end
  end
end

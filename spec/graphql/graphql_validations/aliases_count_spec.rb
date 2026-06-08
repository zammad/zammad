# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlValidations::AliasesCount do
  let(:schema) do
    Class.new(Gql::ZammadSchema) do
      query(Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :dummy, String, null: true # rubocop:disable GraphQL/FieldDescription
        def dummy() = 'ok'
      end)
    end
  end

  context 'when too many directives are given' do
    let(:query) do
      "{ dummy alias0: __typename
               alias1: __typename
               alias2: __typename
               alias3: __typename
               alias4: __typename
               alias5: __typename
               alias6: __typename }"
    end

    it 'raises an error' do
      expect { schema.execute(query) }
        .to raise_error(GraphqlValidations::Error, 'Too many aliases given (maximum is 5)')
    end
  end

  context 'when within directive limit' do
    let(:query) { '{ dummy alias0: __typename }' }

    it 'does not raise an error' do
      expect { schema.execute(query) }.not_to raise_error
    end
  end
end

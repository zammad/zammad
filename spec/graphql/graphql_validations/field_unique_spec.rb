# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlValidations::FieldUnique do
  let(:schema) do
    Class.new(Gql::ZammadSchema) do
      query(Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :dummy, String, null: true # rubocop:disable GraphQL/FieldDescription
        def dummy() = 'ok'
      end)
    end
  end

  context 'when duplicate fields given' do
    let(:query) { '{ dummy __typename __typename }' }

    it 'raises an error' do
      expect { schema.execute(query) }
        .to raise_error(GraphqlValidations::Error,
                        "Field '__typename' is duplicated in the same selection set")
    end

    context 'when same names are in different selection sets' do
      let(:query) { '{ dummy { __typename } another: dummy { __typename } }' }

      it 'does not raise an error' do
        expect { schema.execute(query) }.not_to raise_error
      end
    end
  end
end

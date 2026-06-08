# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlValidations::DirectivesCount do
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
    let(:query) { '{ dummy @a @b @c @d @e @f @g @h @i @j @k }' }

    it 'raises an error' do
      expect { schema.execute(query) }
        .to raise_error(GraphqlValidations::Error, 'Too many directives given (maximum is 5)')
    end
  end

  context 'when within directive limit' do
    let(:query) { '{ dummy @aa }' }

    it 'does not raise an error' do
      expect { schema.execute(query) }.not_to raise_error
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlValidations::AliasesCount do
  let(:schema) do
    Class.new(Gql::ZammadSchema) do
      query(Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :dummy, String, null: true
        def dummy() = 'ok'
      end)
    end
  end

  let(:query) do
    aliases = Array.new(aliases_count) { |i| "alias#{i}: __typename" }.join(' ')

    "{ dummy #{aliases} }"
  end

  context 'when too many aliases are given' do
    let(:aliases_count) { 11 }

    it 'raises an error' do
      expect { schema.execute(query) }
        .to raise_error(GraphqlValidations::Error, 'Too many aliases given (maximum is 10)')
    end
  end

  context 'when exactly at the alias limit' do
    let(:aliases_count) { 10 }

    it 'does not raise an error' do
      expect { schema.execute(query) }.not_to raise_error
    end
  end

  context 'when within alias limit' do
    let(:aliases_count) { 1 }

    it 'does not raise an error' do
      expect { schema.execute(query) }.not_to raise_error
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/graphql_authorize_disallowed'

RSpec.describe RuboCop::Cop::Zammad::GraphqlAuthorizeDisallowed, :aggregate_failures, type: :rubocop do
  context 'when a Graphql operation' do
    it 'rejects self.authorize class method' do
      expect_offense(<<~RUBY)
        module Gql::Queries
          class BaseQuery
            def self.authorize(user)
                     ^^^^^^^^^ GraphQL operations must not define an `self.authorize` method. Use helpers or authorized?
            end
          end
        end
      RUBY
    end

    it 'accepts authorize instance method' do
      expect_no_offenses(<<~RUBY)
        module Gql::Queries
          class Query
            def authorize(user)
            end
          end
        end
      RUBY
    end
  end

  context 'when not a Graphql operation' do
    it 'accepts self.authorize' do
      expect_no_offenses(<<~RUBY)
        module Gql
          class Type
            def self.authorize(user)
            end
          end
        end
      RUBY
    end
  end
end

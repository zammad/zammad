# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/graphql_authorize_allow_public_access'

RSpec.describe RuboCop::Cop::Zammad::GraphqlAuthorizeAllowPublicAccess, :aggregate_failures, type: :rubocop do
  it 'accepts allow_public_access!' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          allow_public_access!
        end
      end
    RUBY
  end

  it 'rejects self.authorize method that returns true' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def self.authorize(_obj, _ctx)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method that returns `true` with `allow_public_access!`.
            true
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          allow_public_access!
        end
      end
    RUBY
  end

  it 'rejects instance authorize method that returns true' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorize(obj, ctx)
          ^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method that returns `true` with `allow_public_access!`.
            true
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          allow_public_access!
        end
      end
    RUBY
  end

  it 'rejects self.authorize with various parameter names' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def self.authorize(user, context)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method that returns `true` with `allow_public_access!`.
            true
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          allow_public_access!
        end
      end
    RUBY
  end

  it 'rejects self.authorize with various parameter names and different content in the method body' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def self.authorize(user, context)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method that returns `true` with `allow_public_access!`.
            # Some comment
            puts "Authorizing..."

            true
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          allow_public_access!
        end
      end
    RUBY
  end

  it 'accepts authorize method that returns conditional logic' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def self.authorize(_obj, _ctx)
            _ctx.current_user.present?
          end
        end
      end
    RUBY
  end

  it 'accepts authorize method that raises' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def self.authorize(_obj, _ctx)
            raise Pundit::NotAuthorizedError
          end
        end
      end
    RUBY
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/graphql_csrf_skip_verification'

RSpec.describe RuboCop::Cop::Zammad::GraphqlCsrfSkipVerification, :aggregate_failures, type: :rubocop do
  it 'accepts skip_csrf_verification!' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          skip_csrf_verification!
        end
      end
    RUBY
  end

  it 'rejects self.requires_csrf_verification? method that returns false' do
    expect_offense(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def self.requires_csrf_verification?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `requires_csrf_verification?` method that returns `false` with `skip_csrf_verification!`.
            false
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          skip_csrf_verification!
        end
      end
    RUBY
  end

  it 'rejects instance requires_csrf_verification? method that returns false' do
    expect_offense(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def requires_csrf_verification?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `requires_csrf_verification?` method that returns `false` with `skip_csrf_verification!`.
            false
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          skip_csrf_verification!
        end
      end
    RUBY
  end

  it 'rejects self.requires_csrf_verification? with multi-statement body' do
    expect_offense(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def self.requires_csrf_verification?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `requires_csrf_verification?` method that returns `false` with `skip_csrf_verification!`.
            # Some comment
            puts "CSRF check disabled"

            false
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          skip_csrf_verification!
        end
      end
    RUBY
  end

  it 'accepts requires_csrf_verification? method that returns conditional logic' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def self.requires_csrf_verification?
            Rails.env.production?
          end
        end
      end
    RUBY
  end

  it 'accepts requires_csrf_verification? method that returns true' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def self.requires_csrf_verification?
            true
          end
        end
      end
    RUBY
  end
end

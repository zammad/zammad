# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/graphql_authorize_requires_permission'

RSpec.describe RuboCop::Cop::Zammad::GraphqlAuthorizeRequiresPermission, :aggregate_failures, type: :rubocop do
  it 'accepts requires_permission' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          requires_permission 'admin.channel_email'
        end
      end
    RUBY
  end

  it 'rejects authorize method checking ctx.current_user.permissions?' do
    expect_offense(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def authorize(_obj, ctx)
          ^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method with `requires_permission` when checking user permission.
            ctx.current_user.permissions?('admin.channel_email')
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          requires_permission 'admin.channel_email'
        end
      end
    RUBY
  end

  it 'rejects self.authorize method checking ctx.current_user.permissions?' do
    expect_offense(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def self.authorize(_obj, ctx)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method with `requires_permission` when checking user permission.
            ctx.current_user.permissions?('admin.channel_email')
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          requires_permission 'admin.channel_email'
        end
      end
    RUBY
  end

  it 'rejects authorize method with different permission name' do
    expect_offense(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def authorize(obj, context)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorize` method with `requires_permission` when checking user permission.
            context.current_user.permissions?('ticket.agent')
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          requires_permission 'ticket.agent'
        end
      end
    RUBY
  end

  it 'accepts authorize method with other logic' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def authorize(_obj, ctx)
            ctx.current_user.admin? && ctx.current_user.permissions?('admin.channel_email')
          end
        end
      end
    RUBY
  end

  it 'accepts authorize method checking different method' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def authorize(_obj, ctx)
            ctx.current_user.admin?
          end
        end
      end
    RUBY
  end

  it 'accepts authorize method with conditional logic' do
    expect_no_offenses(<<~RUBY)
      module Gql::Mutations
        class BaseMutation
          def authorize(_obj, ctx)
            if ctx.some_check?
              ctx.current_user.permissions?('admin.channel_email')
            end
          end
        end
      end
    RUBY
  end
end

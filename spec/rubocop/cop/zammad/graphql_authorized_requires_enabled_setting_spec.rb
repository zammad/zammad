# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/graphql_authorized_requires_enabled_setting'

RSpec.describe RuboCop::Cop::Zammad::GraphqlAuthorizedRequiresEnabledSetting, :aggregate_failures, type: :rubocop do
  it 'accepts requires_enabled_setting' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'ui_desktop_beta_switch'
        end
      end
    RUBY
  end

  it 'rejects authorized? method with Setting.get && super pattern' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
          ^^^^^^^^^^^^^^^^^^^^ Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.
            Setting.get('ui_desktop_beta_switch') && super
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'ui_desktop_beta_switch'
        end
      end
    RUBY
  end

  it 'rejects authorized? method with different setting name' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(obj, ctx)
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.
            Setting.get('mobile_feature_flag') && super
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'mobile_feature_flag'
        end
      end
    RUBY
  end

  it 'rejects self.authorized? class method with Setting.get && super pattern' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def self.authorized?(...)
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.
            Setting.get('some_feature') && super
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'some_feature'
        end
      end
    RUBY
  end

  it 'rejects authorized? method with Setting.get only (no super)' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
          ^^^^^^^^^^^^^^^^^^^^ Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.
            Setting.get('ui_desktop_beta_switch')
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'ui_desktop_beta_switch'
        end
      end
    RUBY
  end

  it 'rejects authorized? method with multiple Setting.get calls' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
          ^^^^^^^^^^^^^^^^^^^^ Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.
            Setting.get('feature_one') && Setting.get('feature_two')
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'feature_one'
          requires_enabled_setting 'feature_two'
        end
      end
    RUBY
  end

  it 'rejects authorized? method with multiple Setting.get calls and super' do
    expect_offense(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
          ^^^^^^^^^^^^^^^^^^^^ Replace `authorized?` method with `requires_enabled_setting` when checking Setting.get.
            Setting.get('feature_one') && Setting.get('feature_two') && super
          end
        end
      end
    RUBY
    expect_correction(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          requires_enabled_setting 'feature_one'
          requires_enabled_setting 'feature_two'
        end
      end
    RUBY
  end

  it 'accepts authorized? method with different logic' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
            current_user.admin? && super
          end
        end
      end
    RUBY
  end

  it 'accepts authorized? method with Setting.get mixed with other method calls' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
            Setting.get('ui_desktop_beta_switch') && current_user.admin?
          end
        end
      end
    RUBY
  end

  it 'accepts authorized? method with only super' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
            super
          end
        end
      end
    RUBY
  end

  it 'accepts authorized? method with super but no Setting.get' do
    expect_no_offenses(<<~RUBY)
      module Gql::Queries
        class BaseQuery
          def authorized?(...)
            some_condition? && super
          end
        end
      end
    RUBY
  end
end

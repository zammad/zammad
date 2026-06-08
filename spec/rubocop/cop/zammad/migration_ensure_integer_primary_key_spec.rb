# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/migration_ensure_integer_primary_key'

RSpec.describe RuboCop::Cop::Zammad::MigrationEnsureIntegerPrimaryKey, :config do
  it 'accepts hardcoded id: :bigserial' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users, id: :bigserial do |t|
          end
        end
      end
    RUBY
  end

  it 'requires id: :integer in 5.1+ migrations' do
    expect_offense(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users do |t|
          ^^^^^^^^^^^^^^^^^^^ Rails 5.1+ migrations must add id: :integer to ensure primary key is integer, not bigint.
          end
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users, id: :integer do |t|
          end
        end
      end
    RUBY
  end

  it 'requires id: :integer in 5.1+ migrations with new timestamp' do
    expect_offense(<<~RUBY, 'db/migrate/20250701000000_create_users.rb')
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users do |t|
          ^^^^^^^^^^^^^^^^^^^ Rails 5.1+ migrations must add id: :integer to ensure primary key is integer, not bigint.
          end
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users, id: :integer do |t|
          end
        end
      end
    RUBY
  end

  it 'accepts no id: :integer in old 5.1+ migration' do
    expect_no_offenses(<<~RUBY, 'db/migrate/20240701000000_test.rb')
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users do |t|
          end
        end
      end
    RUBY
  end

  it 'accepts id: false for ID-less tables' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :users, id: false do |t|
          end
        end
      end
    RUBY
  end

  it 'accepts no id specified for older migrations' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.0]
        def change
          create_table :users do |t|
          end
        end
      end
    RUBY
  end
end

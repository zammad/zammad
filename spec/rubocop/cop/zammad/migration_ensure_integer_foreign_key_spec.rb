# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/migration_ensure_integer_foreign_key'

RSpec.describe RuboCop::Cop::Zammad::MigrationEnsureIntegerForeignKey, :config do
  it 'requires type: :integer on t.references for newer migrations' do
    expect_offense(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :posts do |t|
            t.references :user
            ^^^^^^^^^^^^^^^^^^ Rails 5.1+ migrations must add type: :integer to references setup.
          end
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :posts do |t|
            t.references :user, type: :integer
          end
        end
      end
    RUBY
  end

  it 'requires type: :integer on t.references for newer migrations with new timestamp' do
    expect_offense(<<~RUBY, 'db/migrate/20250701000000_create_users.rb')
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :posts do |t|
            t.references :user
            ^^^^^^^^^^^^^^^^^^ Rails 5.1+ migrations must add type: :integer to references setup.
          end
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :posts do |t|
            t.references :user, type: :integer
          end
        end
      end
    RUBY
  end

  it 'accepts no type: :integer on t.references for old migrations' do
    expect_no_offenses(<<~RUBY, 'db/migrate/20240701000000_create_users.rb')
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :posts do |t|
            t.references :user
          end
        end
      end
    RUBY
  end

  it 'allows type: :bigint in t.references' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          create_table :posts do |t|
            t.references :user, type: :bigint
          end
        end
      end
    RUBY
  end

  it 'requires type: :integer on add_references for newer migrations' do
    expect_offense(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          add_reference :posts, :user
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Rails 5.1+ migrations must add type: :integer to references setup.
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          add_reference :posts, :user, type: :integer
        end
      end
    RUBY
  end

  it 'accepts type: :bigint in add_reference for newer migrations' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.1]
        def change
          add_reference :posts, :user, type: :bigint
        end
      end
    RUBY
  end

  it 'accepts no type: in t.references for older migrations' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.0]
        def change
          create_table :posts do |t|
            t.references :user
          end
        end
      end
    RUBY
  end

  it 'accepts type: :integer in t.references for older migrations' do
    expect_no_offenses(<<~RUBY)
      class Test < ActiveRecord::Migration[5.0]
        def change
          add_reference :posts, :user
        end
      end
    RUBY
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# require all database migrations so we can test them without manual require
Rails.root.join('db/migrate').children.each do |migration|
  require migration.to_s
end

module DbMigrationHelper

  # Provides a helper method to execute a migration for the current class.
  # Make sure to define type: :db_migration in your RSpec.describe call.
  #
  # @param [Symbol] direction the migration should take (:up or :down)
  # @yield [instance] Yields the created instance of the
  #   migration to allow expectations or other changes to it
  #
  # @example
  #  migrate
  #
  # @example
  #  migrate(:down)
  #
  # @return [nil]
  def migrate(direction = :up)
    instance = described_class.new
    yield(instance) if block_given?

    instance.suppress_messages do
      instance.migrate(direction)
    end
  end

  # Provides a helper method to remove foreign_keys if exist.
  # Make sure to define type: :db_migration in your RSpec.describe call
  # and add `self.use_transactional_tests = false` to your context.
  #
  # ATTENTION: We do not use the same arguments as the internally
  #            used methods since giving a table name
  #            as a second argument as e.g.
  #            `remove_foreign_key(:online_notifications, :users)`
  #            doesn't remove the index at first execution on at least MySQL
  #
  # @param [Symbol] from_table the name of the table with the foreign_key column
  # @param [Symbol] column the name of the foreign_key column
  #
  # @example
  #  without_foreign_key(:online_notifications, column: :user_id)
  #
  # @return [nil]
  def without_foreign_key(from_table, column:)
    suppress_messages do
      break if !foreign_key_exists?(from_table, column: column)

      remove_foreign_key(from_table, column: column)
    end
  end

  # Helper method for setting up specs on DB migrations that add columns.
  # Make sure to define type: :db_migration in your RSpec.describe call
  # and add `self.use_transactional_tests = false` to your context.
  #
  # @param [Symbol] from_table the name of the table with the indexed column
  # @param [Symbol] name(s) of indexed column(s)
  #
  # @example
  #  without_column(:online_notifications, column: :user_id)
  #
  # @return [nil]
  def without_column(from_table, column:)
    suppress_messages do
      Array(column).each do |elem|
        next if !column_exists?(from_table, elem)

        remove_column(from_table, elem)
      end
    end
  end

  # Helper method for setting up specs on DB migrations that add indices.
  # Make sure to define type: :db_migration in your RSpec.describe call
  # and add `self.use_transactional_tests = false` to your context.
  #
  # @param [Symbol] from_table the name of the table with the indexed column
  # @param [Symbol] name(s) of indexed column(s)
  #
  # @example
  #  without_index(:online_notifications, column: :user_id)
  #
  # @return [nil]
  def without_index(from_table, column:)
    suppress_messages do
      break if !index_exists?(from_table, column)

      remove_index(from_table, column: column)
    end
  end

  # Enables the usage of `ActiveRecord::Migration` methods.
  #
  # @see ActiveRecord::Migration
  #
  # @example
  #  remove_foreign_key(:online_notifications, :users)
  #
  # @return [nil]
  def method_missing(method, *args, &blk)
    ActiveRecord::Migration.send(method, *args, &blk)
  rescue NoMethodError
    super
  end

  # Enables the usage of `ActiveRecord::Migration` methods.
  #
  # @see ActiveRecord::Migration
  #
  # @example
  #  remove_foreign_key(:online_notifications, :users)
  #
  # @return [nil]
  def respond_to_missing?(*)
    true
  end

  # Provides a helper method to check if migration class adds a foreign key.
  # Make sure to define type: :db_migration in your RSpec.describe call
  # and add `self.use_transactional_tests = false` to your context.
  #
  # @param [Symbol] from_table the name of the table with the foreign_key column
  # @param [Symbol] column the name of the foreign_key column
  #
  # @example
  #  adds_foreign_key(:online_notifications, column: :user_id)
  #
  # @return [nil]
  def adds_foreign_key(from_table, column:)
    without_foreign_key(from_table, column: column)

    suppress_messages do
      expect do
        migrate
      end.to change {
        foreign_key_exists?(from_table, column: column)
      }
    end
  end

  def self.included(base)

    # Execute in RSpec class context
    base.class_exec do

      # This method simulates a system that is is already initialized
      #  aka `Setting.exists?(name: 'system_init_done')`
      #  It's possible to simulate a not yet initialized system by adding the
      #  meta tag `system_init_done` to `false` to the needing example:
      #
      # @example
      #  it 'does stuff in an unitialized system', system_init_done: false do
      #
      before(:each) do |example|
        initialized = example.metadata.fetch(:system_init_done, true)
        system_init_done(initialized)
      end
    end
  end

end

RSpec.configure do |config|
  config.include DbMigrationHelper, type: :db_migration
end

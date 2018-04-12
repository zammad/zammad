# require all database migrations so we can test them without manual require
Rails.root.join('db', 'migrate').children.each do |migration|
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

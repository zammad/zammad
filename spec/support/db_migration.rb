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
end

RSpec.configure do |config|
  config.include DbMigrationHelper, type: :db_migration
end

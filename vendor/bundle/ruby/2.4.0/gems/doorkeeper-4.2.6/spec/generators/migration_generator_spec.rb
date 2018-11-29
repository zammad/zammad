require 'spec_helper_integration'
require 'generators/doorkeeper/migration_generator'

describe 'Doorkeeper::MigrationGenerator' do
  include GeneratorSpec::TestCase

  tests Doorkeeper::MigrationGenerator
  destination ::File.expand_path('../tmp/dummy', __FILE__)

  describe 'after running the generator' do
    before :each do
      prepare_destination
      run_generator
    end

    it 'creates a migration' do
      assert_migration 'db/migrate/create_doorkeeper_tables.rb'
    end
  end
end

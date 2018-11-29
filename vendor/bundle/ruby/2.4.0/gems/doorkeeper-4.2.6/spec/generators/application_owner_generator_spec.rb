require 'spec_helper_integration'
require 'generators/doorkeeper/application_owner_generator'

describe 'Doorkeeper::ApplicationOwnerGenerator' do
  include GeneratorSpec::TestCase

  tests Doorkeeper::ApplicationOwnerGenerator
  destination ::File.expand_path('../tmp/dummy', __FILE__)

  describe 'after running the generator' do
    before :each do
      prepare_destination
      FileUtils.mkdir(::File.expand_path('config', Pathname(destination_root)))
      FileUtils.copy_file(::File.expand_path('../templates/routes.rb', __FILE__), ::File.expand_path('config/routes.rb', Pathname.new(destination_root)))
      run_generator
    end

    it 'creates a migration' do
      assert_migration 'db/migrate/add_owner_to_application.rb'
    end
  end
end

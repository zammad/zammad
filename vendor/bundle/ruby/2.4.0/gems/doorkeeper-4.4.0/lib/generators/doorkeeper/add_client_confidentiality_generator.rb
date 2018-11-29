# frozen_string_literal: true

require 'rails/generators/active_record'

module Doorkeeper
  class AddClientConfidentialityGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration
    source_root File.expand_path('templates', __dir__)
    desc 'Adds a migration to fix CVE-2018-1000211.'

    def install
      migration_template(
        'add_confidential_to_application_migration.rb.erb',
        'db/migrate/add_confidential_to_doorkeeper_application.rb',
        migration_version: migration_version
      )
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    private

    def migration_version
      if ::ActiveRecord::VERSION::MAJOR >= 5
        "[#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end

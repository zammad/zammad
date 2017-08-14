# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'ldap'
require 'ldap/group'

module Import
  class Ldap < Import::IntegrationBase

    # Provides the name that is used in texts visible to the user.
    #
    # @example
    #  Import::Ldap.display_name
    #  #=> "LDAP"
    #
    # return [String]
    def self.display_name
      identifier.upcase
    end

    private

    def start_import
      Import::Ldap::UserFactory.reset_statistics

      Import::Ldap::UserFactory.import(
        config:     @import_job.payload,
        dry_run:    @import_job.dry_run,
        import_job: @import_job
      )

      @import_job.result = Import::Ldap::UserFactory.statistics
    end
  end
end

require 'ldap'
require 'ldap/group'

module Import
  class Ldap

    def initialize(import_job)
      @import_job = import_job

      if !Setting.get('ldap_integration') && !@import_job.dry_run
        raise "LDAP integration deactivated, check Setting 'ldap_integration'."
      end

      start_import
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

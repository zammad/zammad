# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'ldap'
require 'ldap/group'

module Import
  class Ldap < Import::Base

    # Checks if the integration is activated and configured.
    # Otherwise it won't get queued since it will display
    # an error which is confusing and wrong.
    #
    # @example
    #  Import::LDAP.queueable?
    #  #=> true
    #
    # return [Boolean]
    def self.queueable?
      Setting.get('ldap_integration') && Setting.get('ldap_config').present?
    end

    # Starts a live or dry run LDAP import.
    #
    # @example
    #  instance = Import::LDAP.new(import_job)
    #
    # @raise [RuntimeError] Raised if an import should start but the ldap integration is disabled
    #
    # return [nil]
    def start
      return if !requirements_completed?
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

    def requirements_completed?
      return true if @import_job.dry_run

      if !Setting.get('ldap_integration')
        message = 'Sync cancelled. LDAP integration deactivated. Activate via the switch.'
      elsif Setting.get('ldap_config').blank? && @import_job.payload.blank?
        message = 'Sync cancelled. LDAP configration or ImportJob payload missing.'
      end

      return true if !message

      @import_job.update_attribute(:result, {
                                     info: message
                                   })

      false
    end
  end
end

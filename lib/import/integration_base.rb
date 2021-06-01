# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import

  # This base class handles regular integrations.
  # It provides generic interfaces for settings and active state.
  # It ensures that all requirements for a regular integration are met before a import can start.
  # It handles the case of an Scheduler interruption.
  #
  # It's required to implement the +start_import+ method which only has to start the import.
  class IntegrationBase < Import::Base

    def self.inherited(subclass)
      super

      subclass.extend(Forwardable)

      # delegate instance methods to the generic class implementations
      subclass.delegate %i[identifier active? config display_name] => subclass
    end

    # Defines the integration identifier used for
    # automatic config lookup and error message generation.
    #
    # @example
    #  Import::Ldap.identifier
    #  #=> "Ldap"
    #
    # return [String]
    def self.identifier
      name.split('::').last
    end

    # Provides the name that is used in texts visible to the user.
    #
    # @example
    #  Import::Exchange.display_name
    #  #=> "Exchange"
    #
    # return [String]
    def self.display_name
      identifier
    end

    # Checks if the integration is active.
    #
    # @example
    #  Import::Ldap.active?
    #  #=> true
    #
    # return [Boolean]
    def self.active?
      Setting.get("#{identifier.downcase}_integration") || false
    end

    # Provides the integration configuration.
    #
    # @example
    #  Import::Ldap.config
    #  #=> {"ssl_verify"=>true, "host_url"=>"ldaps://192...", ...}
    #
    # return [Hash] the configuration
    def self.config
      Setting.get("#{identifier.downcase}_config") || {}
    end

    # Stores the integration configuration.
    #
    # @example
    #  Import::Ldap.config = {"ssl_verify"=>true, "host_url"=>"ldaps://192...", ...}
    #
    # return [nil]
    def self.config=(value)
      Setting.set("#{identifier.downcase}_config", value)
    end

    # Checks if the integration is activated and configured.
    # Otherwise it won't get queued since it will display
    # an error which is confusing and wrong.
    #
    # @example
    #  Import::Ldap.queueable?
    #  #=> true
    #
    # return [Boolean]
    def self.queueable?
      active? && config.present?
    end

    # Starts a live or dry run import.
    #
    # @example
    #  instance = Import::Ldap.new(import_job)
    #
    # @raise [RuntimeError] Raised if an import should start but the integration is disabled
    #
    # return [nil]
    def start
      return if !requirements_completed?

      start_import
    end

    # Gets called when the Scheduler gets (re-)started and an ImportJob was still
    # in the queue. The job will always get restarted to avoid the gap till the next
    # run triggered by the Scheduler. The result will get updated to inform the user
    # in the agent interface result view.
    #
    # @example
    #  instance = Import::Ldap.new(import_job)
    #  instance.reschedule?(delayed_job)
    #  #=> true
    #
    # return [true]
    def reschedule?(_delayed_job)
      inform('Restarting due to scheduler restart.')
      true
    end

    private

    def start_import
      raise "Missing implementation of method '#{__method__}' for #{self.class.name}"
    end

    def requirements_completed?
      return true if @import_job.dry_run

      if !active?
        message = "Sync cancelled. #{display_name} integration deactivated. Activate via the switch."
      elsif config.blank? && @import_job.payload.blank?
        message = "Sync cancelled. #{display_name} configration or ImportJob payload missing."
      end

      return true if !message

      inform(message)
      false
    end

    def inform(message)
      @import_job.update!(result: {
                            info: message
                          })
    end
  end
end

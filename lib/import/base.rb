# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Base

    # Checks if the backend is active.
    #
    # @example
    #  Import::ExampleBackend.active?
    #  #=> true
    #
    # return [Boolean]
    def self.active?
      true
    end

    # Checks if the backend is able to get queued by the Scheduler.
    #
    # @example
    #  Import::ExampleBackend.queueable?
    #  #=> true
    #
    # return [Boolean]
    def self.queueable?
      true
    end

    # Checks if the backend is able to get rescheduled in case the Scheduler
    # got (re-)started while this ImportJob was running. Defaults to false.
    #
    # @example
    #  instance = Import::LDAP.new(import_job)
    #  instance.reschedule?(delayed_job)
    #  #=> false
    #
    # return [false]
    def reschedule?(_delayed_job)
      false
    end

    # Initializes a new instance with a stored reference to the ImportJob.
    #
    # @example
    #  instance = Import::ExampleBackend.new(import_job)
    #
    # return [Import::ExampleBackend]
    def initialize(import_job)
      @import_job = import_job
    end

    # Starts the life or dry run import of the backend.
    #
    # @example
    #  instance = Import::ExampleBackend.new(import_job)
    #
    # @raise [RuntimeError] Raised if the implementation of this mandatory method is missing
    #
    # return [nil]
    def start
      raise "Missing implementation of the 'start' method."
    end
  end
end

# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Base

    # Checks if the able to get queued by the scheduler.
    #
    # @example
    #  Import::ExampleBackend.queueable?
    #  #=> true
    #
    # return [Boolean]
    def self.queueable?
      true
    end

    # Initializes a new instance with a stored reference to the import job.
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
      raise "Missing implementation if the 'start' method."
    end
  end
end

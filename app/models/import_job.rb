# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ImportJob < ApplicationModel

  store :payload
  store :result

  # Starts the import backend class based on the name attribute.
  # Import backend class is initialized with the current instance.
  # Logs the start and end time (if ended successfully) and logs
  # exceptions into result if they happen.
  #
  # @example
  #  import = ImportJob.new(name: 'Import::Ldap', payload: Setting.get('ldap_config'))
  #  import.start
  #
  # return [nil]
  def start
    self.started_at = Time.zone.now
    save
    name.constantize.new(self)
  rescue => e
    Rails.logger.error e

    # rubocop:disable Style/RedundantSelf
    if !self.result.is_a?(Hash)
      self.result = {}
    end
    self.result[:error] = e.message
    # rubocop:enable Style/RedundantSelf
  ensure
    self.finished_at = Time.zone.now
    save
  end

  # Convenience wrapper around the start method for starting (delayed) dry runs.
  # Logs the start and end time (if ended successfully) and logs
  # exceptions into result if they happen.
  # Only one running or pending dry run per backend is possible at the same time.
  #
  # @param [Hash] params the params used to initialize the ImportJob instance.
  # @option params [Boolean] :delay Defines if job should get executed delayed. Default is true.

  # @example
  #  import = ImportJob.dry_run(name: 'Import::Ldap', payload: Setting.get('ldap_config'), delay: false)
  #
  # return [nil]
  def self.dry_run(params)

    return if exists?(name: params[:name], dry_run: true, finished_at: nil)

    params[:dry_run] = true
    instance = create(params.except(:delay))

    if params.fetch(:delay, true)
      instance.delay.start
    else
      instance.start
    end
  end

  # Starts all import jobs that have not started yet and are no dry runs.
  #
  # @example
  #  ImportJob.start
  #
  # return [nil]
  def self.start
    where(started_at: nil, dry_run: false).each(&:start)
  end
end

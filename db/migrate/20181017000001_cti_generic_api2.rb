# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CtiGenericApi2 < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')
    return if !column_exists?(:cti_logs, :initialized_at)
    return if column_exists?(:cti_logs, :initialized_at_cleanup)

    if ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
      # disable the MySQL strict_mode for the current connection
      execute("SET sql_mode = ''")
      add_column :cti_logs, :initialized_at_cleanup, :timestamp, limit: 3, null: true, default: '0000-00-00 00:00:00'
    else
      add_column :cti_logs, :initialized_at_cleanup, :timestamp, limit: 3, null: true
    end

    Cti::Log.connection.schema_cache.clear!
    Cti::Log.reset_column_information

    # clenaup table records
    Cti::Log.order(created_at: :desc).limit(2000).each do |log|
      if log.initialized_at
        begin
          initialized_at = Time.zone.parse(log.initialized_at)
          log.update_column(:initialized_at_cleanup, initialized_at) # rubocop:disable Rails/SkipsModelValidations
          if initialized_at && log.start_at
            log.update_column(:duration_waiting_time, log.start_at.to_i - initialized_at.to_i) # rubocop:disable Rails/SkipsModelValidations
          else
            log.update_column(:duration_waiting_time, nil) # rubocop:disable Rails/SkipsModelValidations
          end
        rescue => e
          Rails.logger.error e
        end
      end
      if log.end_at && log.start_at
        log.update_column(:duration_talking_time, log.end_at.to_i - log.start_at.to_i) # rubocop:disable Rails/SkipsModelValidations
      else
        log.update_column(:duration_talking_time, nil) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    remove_column(:cti_logs, :initialized_at)
    Cti::Log.connection.schema_cache.clear!
    Cti::Log.reset_column_information

    rename_column :cti_logs, :initialized_at_cleanup, :initialized_at
    Cti::Log.connection.schema_cache.clear!
    Cti::Log.reset_column_information
  end
end

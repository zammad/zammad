# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue5091TimezoneDefault < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    set_timezone_to_utc_if_needed
    add_validation_preference
  end

  private

  def set_timezone_to_utc_if_needed
    current_timezone = Setting.get('timezone_default')

    return if Setting::Validation::TimeZone.valid_timezone_identifier?(current_timezone)

    Setting.set('timezone_default', 'UTC')
  end

  def add_validation_preference
    setting = Setting.find_by(name: 'timezone_default')
    setting.preferences[:validations] = ['Setting::Validation::TimeZone']
    setting.save!
  end
end

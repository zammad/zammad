# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::TimeZone < Setting::Validation::Base
  def run
    if value.blank?
      return result_failed(__('Time zone is required.'))
    end

    if !self.class.valid_timezone_identifier?(value)
      return result_failed(__('Given time zone is not valid.'))
    end

    result_success
  end

  def self.valid_timezone_identifier?(input)
    ActiveSupport::TimeZone.find_tzinfo input

    true
  rescue TZInfo::InvalidTimezoneIdentifier
    false
  end
end

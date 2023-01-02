# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Setting::Processed::Timezone < Setting::Processed::Backend
  def process_settings!
    setting = @input.find { |name, _| name == 'timezone_default' }

    return if !setting

    value = setting.last['value']

    @input.append ['timezone_default_sanitized', { 'value' => sanitize_timezone(value) }]
  end

  def process_frontend_settings!
    value = @input['timezone_default']

    @input['timezone_default_sanitized'] = sanitize_timezone(value)
  end

  def sanitize_timezone(input)
    return input if timezone_exists? input

    'UTC'
  end

  def timezone_exists?(input)
    ActiveSupport::TimeZone.find_tzinfo input

    true
  rescue TZInfo::InvalidTimezoneIdentifier
    log_warning(input)

    false
  end

  def log_warning(input)
    message = if input.blank?
                'Setting "timezone_default" is empty. Using UTC instead. Please set system timezone.' # rubocop:disable Zammad/DetectTranslatableString
              else
                "Setting \"timezone_default\" is invalid. Using UTC instead of \"#{input}\". Please use valid IANA timezone."
              end

    Rails.logger.warn message
  end
end

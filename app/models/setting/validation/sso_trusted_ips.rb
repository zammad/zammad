# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::SsoTrustedIps < Setting::Validation::Base
  def run
    trusted_ips = Auth::Sso::TrustedIps.new(value)
    return result_success if trusted_ips.blank?

    invalid_entry = trusted_ips.first_invalid_entry
    return result_failed(format(__("'%s' is not a valid IP address or CIDR range."), invalid_entry)) if invalid_entry

    result_success
  end
end

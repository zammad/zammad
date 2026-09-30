# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::MicrosoftOffice365Credentials < Setting::Validation::Base
  def run
    return result_success if value.nil?
    return result_failed(__('Unknown Microsoft cloud.')) if !value.is_a?(Hash)

    ::MicrosoftCloud.new(value.with_indifferent_access[:cloud])
    result_success
  rescue ArgumentError => e
    result_failed(e.message)
  end
end

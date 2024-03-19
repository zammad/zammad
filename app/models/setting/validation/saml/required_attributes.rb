# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::Saml::RequiredAttributes < Setting::Validation::Base

  REQUIRED_ATTRIBUTES = %i[idp_sso_target_url idp_slo_service_url idp_cert name_identifier_format].freeze

  def run
    return result_success if value.blank? || value.deep_symbolize_keys.keys.eql?([:display_name])

    msg = check_prerequisites
    return result_failed(msg) if !msg.nil?

    result_success
  end

  private

  def check_prerequisites
    return "One of the required attributes #{REQUIRED_ATTRIBUTES.map { |e| "'#{e}'" }.join(', ')} is missing." if REQUIRED_ATTRIBUTES.any? { |key| !value.key?(key) || value[key].blank? }

    nil
  end
end

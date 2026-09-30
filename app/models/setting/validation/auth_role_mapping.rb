# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Validates the role mapping within the credentials of a provider. A blank role mapping passes -
#   it is how the role mapping is turned off.
class Setting::Validation::AuthRoleMapping < Setting::Validation::Base

  def run
    return result_success if role_mapping.blank?
    return result_failed(__('The role mapping has to be an object.')) if !role_mapping.is_a?(Hash)
    return result_failed(__('The role mapping attribute has to be a text.')) if !valid_attribute?
    return result_failed(__('The role mapping needs a map of values to role IDs.')) if !valid_map?
    return result_failed(__('Each role mapping needs a value and at least one role.')) if !complete_map?
    return result_failed(__('The behavior for logins without a mapped role is not supported.')) if !valid_unmatched?

    result_success
  end

  private

  def role_mapping
    @role_mapping ||= value.is_a?(Hash) ? value.with_indifferent_access[Authorization::RoleMapping::CREDENTIALS_KEY] : nil
  end

  def config
    @config ||= role_mapping.with_indifferent_access
  end

  def valid_attribute?
    config[:attribute].nil? || config[:attribute].is_a?(String)
  end

  def valid_map?
    return true if config[:map].nil?
    return false if !config[:map].is_a?(Hash)

    config[:map].values.all? { |role_ids| Array.wrap(role_ids).all? { |role_id| role_id.to_s.match?(%r{\A\d+\z}) } }
  end

  def complete_map?
    return true if config[:map].nil?

    config[:map].all? { |key, role_ids| key.to_s.strip.present? && Array.wrap(role_ids).any? }
  end

  def valid_unmatched?
    config[:unmatched].blank? || Authorization::RoleMapping::UNMATCHED_BEHAVIOURS.include?(config[:unmatched])
  end

end

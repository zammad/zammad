# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::RemoveMethodCredentials < Service::User::TwoFactor::Base
  attr_reader :credential_id

  def initialize(credential_id:, **)
    super(**)

    @credential_id = credential_id
  end

  def execute
    validate

    credentials.delete_if { |elem| elem[:public_key] == credential_id }

    if credentials.blank?
      user_preference.destroy!
    else
      user_preference.save!
    end
  end

  private

  def credentials
    @credentials ||= user_preference.configuration[:credentials]
  end

  def validate
    if !user_preference
      raise Exceptions::UnprocessableEntity, __('The given two-factor method is not configured yet.')
    end

    return if credentials&.find { |elem| elem[:public_key] == credential_id }

    raise Exceptions::UnprocessableEntity, __('The two-factor credentials you\'re trying to delete do not exist')
  end
end

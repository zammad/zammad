# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::RemoveLinkedAccount < Service::Base

  attr_reader :provider, :uid, :current_user

  def initialize(provider:, uid:, current_user:)
    super()
    @provider = provider
    @uid = uid
    @current_user = current_user
  end

  def execute
    records = Authorization.where(
      user_id:  @current_user.id,
      provider: @provider,
      uid:      @uid,
    ).destroy_all

    raise Exceptions::UnprocessableEntity, __('The linked account could not be found.') if records.count.zero?
  end
end

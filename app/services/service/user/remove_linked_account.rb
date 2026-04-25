# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::RemoveLinkedAccount < Service::Base
  requires_current_user!

  attr_reader :provider, :uid

  def initialize(provider:, uid:)
    @provider = provider
    @uid = uid
  end

  def execute
    records = current_user
      .authorizations
      .where(provider:, uid:)
      .destroy_all

    raise Exceptions::UnprocessableContent, __('The linked account could not be found.') if records.none?
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Session < ActiveRecord::SessionStore::Session
  include Session::SetsPersistentFlag

  def self.secure_flag?
    # enable runtime change support in test/develop environments
    return https? if !Rails.env.production?

    @secure_flag ||= https?
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    false
  end

  def self.https?
    Setting.get('http_type') == 'https'
  end
end

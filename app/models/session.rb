# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Session < ActiveRecord::SessionStore::Session
  include Session::SetsPersistentFlag
end

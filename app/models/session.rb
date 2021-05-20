class Session < ActiveRecord::SessionStore::Session
  include Session::SetsPersistentFlag
end

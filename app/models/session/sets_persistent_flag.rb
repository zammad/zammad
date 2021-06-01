# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Session::SetsPersistentFlag
  extend ActiveSupport::Concern

  included do
    before_create  :session_set_persistent_flag
    before_update  :session_set_persistent_flag
  end

  private

  # move the persistent attribute from the sub structure
  # to the first level so it gets stored in the database
  # column to make the cleanup lookup more performant
  def session_set_persistent_flag
    return if !data
    return if self[:persistent]

    return if !data['persistent']

    self[:persistent] = data['persistent']
    data.delete('persistent')
  end

end

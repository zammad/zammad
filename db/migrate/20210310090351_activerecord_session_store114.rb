# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ActiverecordSessionStore114 < ActiveRecord::Migration[5.2]
  def change
    ActionDispatch::Session::ActiveRecordStore.session_class.find_each(&:secure!)
  end
end

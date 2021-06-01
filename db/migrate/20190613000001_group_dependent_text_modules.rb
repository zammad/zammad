# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GroupDependentTextModules < ActiveRecord::Migration[5.1]
  def change
    rename_table :text_modules_groups, :groups_text_modules
  end
end

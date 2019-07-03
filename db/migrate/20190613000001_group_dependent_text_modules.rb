class GroupDependentTextModules < ActiveRecord::Migration[5.1]
  def change
    rename_table :text_modules_groups, :groups_text_modules
  end
end

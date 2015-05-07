class RenameAvatarTypo < ActiveRecord::Migration
  def up
    rename_column :avatars, :inital, :initial
  end

  def down
    rename_column :avatars, :initial, :inital
  end
end

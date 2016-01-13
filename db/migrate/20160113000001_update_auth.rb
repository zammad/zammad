class UpdateAuth < ActiveRecord::Migration
  def up
    Setting.where(name:'auth_otrs').destroy_all
  end
end

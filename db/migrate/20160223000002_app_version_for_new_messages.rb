class AppVersionForNewMessages < ActiveRecord::Migration
  def up
    AppVersion.set(true)
  end
end

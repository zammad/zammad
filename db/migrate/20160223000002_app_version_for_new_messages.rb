require 'app_version'
class AppVersionForNewMessages < ActiveRecord::Migration
  def up
    AppVersion.set(true)
  end
end

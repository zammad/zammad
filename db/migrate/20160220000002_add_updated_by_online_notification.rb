class AddUpdatedByOnlineNotification < ActiveRecord::Migration
  def up
    return if OnlineNotification.column_names.include?('updated_by_id')
    add_column :online_notifications, :updated_by_id, :integer
  end
end

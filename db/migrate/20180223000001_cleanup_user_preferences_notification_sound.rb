class CleanupUserPreferencesNotificationSound < ActiveRecord::Migration[5.1]
  def up
    User.with_permissions('ticket.agent').each do |user|
      local_to_h!(user.preferences)
      user.save!
    end

    User.with_permissions('ticket.agent').each do |user|
      next if !user.preferences
      next if !user.preferences[:notification_sound]
      next if !user.preferences[:notification_sound][:enabled]
      if user.preferences[:notification_sound][:enabled] == 'true'
        user.preferences[:notification_sound][:enabled] = true
        user.save!
        next
      end
      next if user.preferences[:notification_sound][:enabled] != 'false'
      user.preferences[:notification_sound][:enabled] = false
      user.save!
      next
    end
  end

  def local_to_h!(value)
    if value.class == ActionController::Parameters
      value = value.permit!.to_h
    end
    if value.class == Hash || value.class == ActiveSupport::HashWithIndifferentAccess
      value.each_key do |local_key|
        value[local_key] = local_to_h!(value[local_key])
      end
    end
    value
  end

end

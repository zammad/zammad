# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CleanupUserPreferencesNotificationSound2 < ActiveRecord::Migration[5.1]

  def local_to_h!(value)
    if value.instance_of?(ActionController::Parameters)
      value = value.permit!.to_h
    end
    if value.instance_of?(Hash) || value.instance_of?(ActiveSupport::HashWithIndifferentAccess)
      value.each_key do |local_key|
        value[local_key] = local_to_h!(value[local_key])
      end
    end
    value
  end

  def local_clear_preferences(user)
    return false if !user
    return false if !user.preferences
    return false if !user.preferences[:notification_sound]
    return false if !user.preferences[:notification_sound][:enabled]

    if user.preferences[:notification_sound][:enabled] == 'true'
      user.preferences[:notification_sound][:enabled] = true
      user.save!
      return true
    end
    return false if user.preferences[:notification_sound][:enabled] != 'false'

    user.preferences[:notification_sound][:enabled] = false
    user.save!
    true
  end

  def up
    User.with_permissions('ticket.agent').each do |user|
      local_to_h!(user.preferences)
      user.save!
    end

    items = SearchIndexBackend.search('preferences.notification_sound.enabled:*', 'User', limit: 3000) || []
    items.each do |item|
      next if !item[:id]

      user = User.find_by(id: item[:id])
      local_to_h!(user.preferences)
      local_clear_preferences(user)
    end

    Organization.all.each do |organization|
      organization.members.each do |user|
        local_to_h!(user.preferences)
        local_clear_preferences(user)
      end
    end

    Delayed::Job.limit(2_000).each do |job|
      Delayed::Worker.new.run(job)
    end
  end

end

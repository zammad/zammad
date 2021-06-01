# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FixedStoreUpgradeRor45 < ActiveRecord::Migration[5.0]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Cache.clear
    [Macro, Taskbar, Calendar, Trigger, Channel, Job, PostmasterFilter, Report::Profile, Setting, Sla, Template].each do |class_name|
      class_name.all.each do |record|

        record.save!
      rescue => e
        Rails.logger.error "Unable to save/update #{class_name}.find(#{record.id}): #{e.message}"

      end
    end

    Channel.all.each do |channel|
      next if channel.options.blank?

      channel.options.each do |key, value|
        channel.options[key] = cleanup(value)
      end
      channel.save!
    end
    User.with_permissions('ticket.agent').each do |user|
      next if user.preferences.blank?

      user.preferences.each do |key, value|
        user.preferences[key] = cleanup(value)
      end
      user.save!
    end
  end

  def cleanup(value)
    if value.instance_of?(ActionController::Parameters)
      value = value.permit!.to_h
    end
    return value if value.class != ActiveSupport::HashWithIndifferentAccess && value.class != Hash

    value.each do |local_key, local_value|
      value[local_key] = cleanup(local_value)
    end
    value
  end
end

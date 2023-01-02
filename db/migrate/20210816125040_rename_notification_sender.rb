# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RenameNotificationSender < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(
      name: 'notification_sender',
    )
    return if !setting

    # rubocop:disable Lint/InterpolationCheck
    setting.state_initial[:value] = '#{config.product_name} <noreply@#{config.fqdn}>'

    if setting.state_current[:value].eql? 'Notification Master <noreply@#{config.fqdn}>'
      setting.state_current[:value] = '#{config.product_name} <noreply@#{config.fqdn}>'
    end
    # rubocop:enable Lint/InterpolationCheck
    setting.save!
  end
end

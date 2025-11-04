# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DropTwitter < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ExternalCredential.find_by(name: 'twitter')&.destroy
    Channel.where(area: 'Twitter::Account').destroy_all
    Permission.find_by(name: 'admin.channel_twitter')&.destroy
    Setting.find_by(name: 'ui_ticket_zoom_article_twitter_initials')&.destroy
    Scheduler.find_by(method: 'Channel.stream')&.destroy
  end
end

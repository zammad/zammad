# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggerRecipientUpdate < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ['auto reply (on new tickets)', 'auto reply (on follow-up of tickets)'].each do |name|

      trigger = Trigger.find_by(name: name)
      next if trigger.blank?
      next if trigger.perform.blank?
      next if trigger.perform['notification.email'].blank?
      next if trigger.perform['notification.email']['recipient'].blank?
      next if trigger.perform['notification.email']['recipient'] != 'ticket_customer'

      trigger.perform['notification.email']['recipient'] = 'article_last_sender'
      trigger.save!
    rescue => e
      Rails.logger.error "Unable to update Trigger.find(#{trigger.id}) '#{trigger.inspect}': #{e.message}"

    end

  end
end

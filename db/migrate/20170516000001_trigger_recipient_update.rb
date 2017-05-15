class TriggerRecipientUpdate < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    ['auto reply (on new tickets)', 'auto reply (on follow up of tickets)'].each { |name|
      trigger = Trigger.find_by(name: name)
      next if !trigger
      next if !trigger.perform
      next if !trigger.perform['notification.email']
      next if !trigger.perform['notification.email']['recipient']
      next if trigger.perform['notification.email']['recipient'] != 'ticket_customer'
      trigger.perform['notification.email']['recipient'] = 'article_last_sender'
      trigger.save
    }

  end
end

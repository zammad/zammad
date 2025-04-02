# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ImproveGroupEmailUiWording < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    email_attribute = ObjectManager::Attribute.for_object('Group').find_by(name: 'email_address_id')
    email_attribute.display            = 'Email Address'
    email_attribute.data_option[:note] = "A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply."
    email_attribute.save!
  end
end

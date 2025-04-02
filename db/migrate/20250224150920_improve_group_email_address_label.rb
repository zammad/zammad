# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ImproveGroupEmailAddressLabel < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    email_attribute = ObjectManager::Attribute.for_object('Group').find_by(name: 'email_address_id')
    email_attribute.display = 'Sending Email Address'
    email_attribute.save!
  end
end

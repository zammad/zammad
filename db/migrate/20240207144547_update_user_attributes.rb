# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class UpdateUserAttributes < ActiveRecord::Migration[7.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_email_attribute
    migrate_role_ids_attribute
    migrate_group_ids_attribute
  end

  private

  def migrate_email_attribute
    email_attribute = user_attribute('email')
    email_attribute.screens[:signup] ||= {}
    email_attribute.screens[:signup]['-all-'] ||= {}
    email_attribute.screens[:signup]['-all-']['null'] = false
    email_attribute.screens[:invite_agent] ||= {}
    email_attribute.screens[:invite_agent]['-all-'] ||= {}
    email_attribute.screens[:invite_agent]['-all-']['null'] = false
    email_attribute.screens[:invite_customer] ||= {}
    email_attribute.screens[:invite_customer]['-all-'] ||= {}
    email_attribute.screens[:invite_customer]['-all-']['null'] = false
    email_attribute.save!(validate: false)
  end

  def migrate_role_ids_attribute
    role_ids_attribute = user_attribute('role_ids')
    role_ids_attribute.data_option[:relation] = 'Role'
    role_ids_attribute.save!(validate: false)
  end

  def migrate_group_ids_attribute
    group_ids_attribute = user_attribute('group_ids')
    group_ids_attribute.screens[:invite_agent] ||= {}
    group_ids_attribute.screens[:invite_agent]['-all-'] ||= {}
    group_ids_attribute.screens[:invite_agent]['-all-']['null'] = true
    group_ids_attribute.save!(validate: false)
  end

  def user_attribute(name)
    ObjectManager::Attribute.for_object('User').find_by(name: name)
  end
end

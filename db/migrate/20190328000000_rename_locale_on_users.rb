# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RenameLocaleOnUsers < ActiveRecord::Migration[5.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')
    return if ActiveRecord::Base.connection.columns('users').map(&:name).exclude?('locale')

    ActiveRecord::Migration.rename_column(:users, :locale, :_locale)
    User.reset_column_information

    attribute = ObjectManager::Attribute.get(
      object: 'User',
      name:   'locale',
    )
    return if !attribute

    attribute.update(name: '_locale')
  end

  def down
    return if ActiveRecord::Base.connection.columns('users').map(&:name).exclude?('_locale')

    ActiveRecord::Migration.rename_column(:users, :_locale, :locale)
    User.reset_column_information

    attribute = ObjectManager::Attribute.get(
      object: 'User',
      name:   '_locale',
    )
    return if !attribute

    attribute.update(name: 'locale')
  end
end

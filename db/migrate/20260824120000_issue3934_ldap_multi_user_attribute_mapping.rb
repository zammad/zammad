# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue3934LdapMultiUserAttributeMapping < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    LdapSource.find_each do |source|
      user_attributes = source.preferences['user_attributes']
      next if user_attributes.blank?

      source.preferences['user_attributes'] = user_attributes.transform_values { |dest| Array.wrap(dest) }
      source.save!
    end
  end
end

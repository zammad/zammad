# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4219LdapWizard < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    LdapSource.find_each do |source|
      source.preferences.delete(:wizardData)
      source.save!
    end
  end
end

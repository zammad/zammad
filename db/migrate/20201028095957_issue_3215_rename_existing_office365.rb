# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3215RenameExistingOffice365 < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # migrate existing Channels and ExternalCredential to new name

    # rubocop:disable Rails/SkipsModelValidations
    Channel.where(area: 'Office365::Account').update_all(area: 'Microsoft365::Account')
    ExternalCredential.where(name: 'office365').update_all(name: 'microsoft365')
    # rubocop:enable Rails/SkipsModelValidations
  end
end

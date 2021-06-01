# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChangeExchangeExternalSyncIdentifier < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup to avoid running the migration
    return if !Setting.exists?(name: 'system_init_done')

    ExternalSync.where(
      source: 'EWS::FolderContact'
    ).update_all( # rubocop:disable Rails/SkipsModelValidations
      source: 'Exchange::FolderContact'
    )
  end

end

class ChangeExchangeExternalSyncIdentifier < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup to avoid running the migration
    return if !Setting.find_by(name: 'system_init_done')

    ExternalSync.where(
      source: 'EWS::FolderContact'
    ).update_all( # rubocop:disable Rails/SkipsModelValidations
      source: 'Exchange::FolderContact'
    )
  end

end

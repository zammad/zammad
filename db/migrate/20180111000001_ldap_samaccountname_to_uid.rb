class LdapSamaccountnameToUid < ActiveRecord::Migration[5.1]

  def up
    # return if it's a new setup to avoid running the migration
    return if !Setting.exists?(name: 'system_init_done')

    Delayed::Job.enqueue MigrationJob::LdapSamaccountnameToUid.new
  end

end

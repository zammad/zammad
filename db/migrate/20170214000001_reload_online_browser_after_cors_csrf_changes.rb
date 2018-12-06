class ReloadOnlineBrowserAfterCorsCsrfChanges < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    AppVersion.set(true, 'app_version')
  end
end

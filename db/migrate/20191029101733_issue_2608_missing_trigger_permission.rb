class Issue2608MissingTriggerPermission < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.find_by(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.trigger',
      note:        'Manage %s',
      preferences: {
        translations: ['Triggers']
      },
    )
  end
end

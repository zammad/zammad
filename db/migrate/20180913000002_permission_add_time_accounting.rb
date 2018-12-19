class PermissionAddTimeAccounting < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.time_accounting',
      note:        'Manage %s',
      preferences: {
        translations: ['Time Accounting']
      },
    )

  end

end

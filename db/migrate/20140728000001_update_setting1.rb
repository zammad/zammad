class UpdateSetting1 < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Send client stats',
      name: 'ui_send_client_stats',
      area: 'System::UI',
      description: 'Send client stats to central server.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ui_send_client_stats',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Client storage',
      name: 'ui_client_storage',
      area: 'System::UI',
      description: 'Use client storage to cache data to perform speed of application.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ui_client_storage',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      frontend: true
    )
  end

  def down
  end
end

class UpdateSettings < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Organization',
      name: 'organization',
      area: 'System::Branding',
      description: 'Will be shown in the app and is included in email footers.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'organization',
            tag: 'input',
          },
        ],
      },
      state: '',
      preferences: { prio: 2 },
      frontend: true
    )
    Setting.create_or_update(
      title: 'Send client stats',
      name: 'ui_send_client_stats',
      area: 'System::UI',
      description: 'Send client stats/error message to central server to improve the usability.',
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
      preferences: { prio: 1 },
      frontend: true
    )
    Setting.create_or_update(
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
      preferences: { prio: 2 },
      frontend: true
    )
  end
end

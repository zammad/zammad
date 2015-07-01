class UpdateSetting2 < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Logo',
      name: 'product_logo',
      area: 'System::CI',
      description: 'Defines the logo of the application, shown in the web interface.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'product_logo',
            tag: 'input',
          },
        ],
      },
      state: 'logo.svg',
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Online Service',
      name: 'system_online_service',
      area: 'Core',
      description: 'Defines if application is used as online service.',
      options: {},
      state: false,
      frontend: true
    )
  end

  def down
  end
end

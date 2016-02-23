class AppVersion < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'App Version',
      name: 'app_version',
      area: 'Core::WebApp',
      description: 'Only used for internal, to propagate current web app version to clients.',
      options: {},
      state: '',
      preferences: { online_service_disable: true },
      frontend: false
    )
  end
end

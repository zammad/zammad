class UpdateMaintenance < ActiveRecord::Migration
  def up
    # can be deleted later, db/seeds.rb already updated
    Setting.create_if_not_exists(
      title: 'Maintenance Mode',
      name: 'maintenance_mode',
      area: 'Core::WebApp',
      description: 'Enable or disable the maintenance mode of Zammad. If enabled, all non-administrators get logged out and only administrators can start a new session.',
      options: {},
      state: false,
      preferences: {},
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Maintenance Login',
      name: 'maintenance_login',
      area: 'Core::WebApp',
      description: 'Put a message on the login page. To change it, click on the text area below and change it inline.',
      options: {},
      state: false,
      preferences: {},
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Maintenance Login',
      name: 'maintenance_login_message',
      area: 'Core::WebApp',
      description: 'Message for login page.',
      options: {},
      state: 'Something about to share. Click here to change.',
      preferences: {},
      frontend: true
    )
  end
end

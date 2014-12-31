class AddDevelopMode < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      :title       => 'Develop System',
      :name        => 'developer_mode',
      :area        => 'Core::Develop',
      :description => 'Defines if application is in developer mode (useful for developer, all users have the same password, password reset will work without email delivery).',
      :options     => {},
      :state       => false,
      :frontend    => true
    )
  end

  def down
  end
end
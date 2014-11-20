class UpdateSetting3 < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      :title       => 'Online Service',
      :name        => 'system_online_service',
      :area        => 'Core',
      :description => 'Defines if application is used as online service.',
      :options     => {},
      :state       => false,
      :frontend    => true
    )
  end

  def down
  end
end
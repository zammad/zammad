require 'user'
require 'setting'
class SettingUpdate < ActiveRecord::Migration
  def up
    count = User.all.count()
    if count > 2
      Setting.create_or_update(
        :title       => 'System Init Done',
        :name        => 'system_init_done',
        :area        => 'Core',
        :description => 'Defines if application is in init mode.',
        :options     => {},
        :state       => true,
        :frontend    => true
      )
    end
  end

  def down
  end
end

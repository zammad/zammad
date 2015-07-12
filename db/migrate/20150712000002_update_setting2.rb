class UpdateSetting2 < ActiveRecord::Migration
  def up

    # add preferences
    add_column :settings, :preferences, :string, limit: 2000, null: true

    # update settings
    %w(product_name ticket_hook chat).each {|setting_name|
      setting = Setting.find_by(name: setting_name)
      next if !setting
      setting.preferences[:render] = true
      setting.save
    }
    %w(product_name).each {|setting_name|
      setting = Setting.find_by(name: setting_name)
      next if !setting
      setting.preferences[:session_check] = true
      setting.save
    }
    setting = Setting.find_by(name: 'product_name')
    setting.preferences[:prio] = 1
    setting.save
    setting = Setting.find_by(name: 'organization')
    setting.preferences[:prio] = 2
    setting.save
    setting = Setting.find_by(name: 'product_logo')
    setting.preferences[:prio] = 3
    setting.save
  end
end

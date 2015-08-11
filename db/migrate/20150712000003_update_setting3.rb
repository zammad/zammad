class UpdateSetting3 < ActiveRecord::Migration
  def up

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
    if setting
      setting.preferences[:prio] = 1
      setting.save
    end
    setting = Setting.find_by(name: 'organization')
    if setting
      setting.preferences[:prio] = 2
      setting.save
    end
    setting = Setting.find_by(name: 'product_logo')
    return if !setting
    setting.preferences[:prio] = 3
    setting.save
  end
end

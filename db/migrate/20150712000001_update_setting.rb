class UpdateSetting < ActiveRecord::Migration
  def up
    %w(product_name product_logo organization).each {|setting_name|
      setting = Setting.find_by(name: setting_name)
      next if !setting
      setting.area = 'System::Branding'
      setting.save
    }
  end
end

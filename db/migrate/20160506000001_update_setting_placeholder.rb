class UpdateSettingPlaceholder < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    names = %w(
      product_name
      organization
      system_id
      fqdn
      http_type
      ticket_hook)
    names.each {|name|
      setting = Setting.find_by(name: name)
      next if !setting
      setting.preferences[:placeholder] = true
      setting.save
    }
  end

end

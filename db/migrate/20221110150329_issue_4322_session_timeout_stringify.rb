# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4322SessionTimeoutStringify < ActiveRecord::Migration[6.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by name: 'session_timeout'

    setting.options['form'].each do |form_option|
      form_option['options'].each do |option|
        option['value'] = option['value'].to_s
      end
    end

    %i[state_current state_initial].each do |attr|
      migrate_attribute setting, attr
    end

    setting.save!
  end

  def migrate_attribute(object, attr)
    hash = object.send(attr)

    hash['value'].each_key do |key|
      hash['value'][key] = hash['value'][key].to_s
    end

    object.send("#{attr}=", hash)
  end
end

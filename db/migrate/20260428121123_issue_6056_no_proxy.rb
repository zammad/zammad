# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6056NoProxy < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'proxy_no')

    return if !setting

    if setting.state_current == setting.state_initial
      setting.state_current = { value: '' }
    end

    setting.description = 'No proxy for these comma-separated addresses. Supports wildcards like *.example.com. Note: Loopback addresses are always excluded from proxying.'
    setting.state_initial = { value: '' }
    setting.options[:form][0][:placeholder] = 'example.com,*.example.org'

    setting.save!
  end
end

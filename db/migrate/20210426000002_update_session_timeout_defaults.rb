# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UpdateSessionTimeoutDefaults < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    defaults = Setting.get('session_timeout')
    %w[default admin ticket.agent ticket.customer].each do |key|
      next if defaults[key].to_i != 172_800

      defaults[key] = 4.weeks.seconds
    end

    Setting.set('session_timeout', defaults)
  end
end

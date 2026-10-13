# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AlternativeFqdnFrontend < ActiveRecord::Migration[8.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'alternative_fqdn')&.update!(frontend: true)
  end
end

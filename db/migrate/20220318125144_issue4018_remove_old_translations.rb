# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4018RemoveOldTranslations < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Translation.where(source: 'FORMAT_DATE', is_synchronized_from_codebase: false).find_each(&:destroy)
  end
end

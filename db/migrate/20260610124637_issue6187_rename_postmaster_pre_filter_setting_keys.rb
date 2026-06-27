# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6187RenamePostmasterPreFilterSettingKeys < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Rename filter keys to reflect updated execution order:
    #   out-of-office check must run before follow-up assignment.
    [
      {
        old_name: '0009_postmaster_filter_follow_up_assignment',
        new_name: '0010_postmaster_filter_follow_up_assignment',
      },
      {
        old_name: '0030_postmaster_filter_out_of_office_check',
        new_name: '0009_postmaster_filter_out_of_office_check',
      },
    ].each do |mapping|
      Setting.find_by(name: mapping[:old_name])&.update(name: mapping[:new_name])
    end
  end
end

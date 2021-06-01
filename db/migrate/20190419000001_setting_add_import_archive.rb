# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingAddImportArchive < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Define postmaster filter.',
      name:        '0018_postmaster_import_archive',
      area:        'Postmaster::PreFilter',
      description: 'Define postmaster filter to import archive mailboxes.',
      options:     {},
      state:       'Channel::Filter::ImportArchive',
      frontend:    false
    )
  end
end

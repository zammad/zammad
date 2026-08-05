# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SettingPostmasterFilterAttachmentReferenceRemove < ActiveRecord::Migration[8.0]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0012_postmaster_filter_attachment_reference_remove',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to remove references to local attachments from incoming emails.',
      options:     {},
      state:       'Channel::Filter::AttachmentReferenceRemove',
      frontend:    false
    )
  end
end

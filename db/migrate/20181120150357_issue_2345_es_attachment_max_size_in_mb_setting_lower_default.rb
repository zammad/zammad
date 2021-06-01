# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2345EsAttachmentMaxSizeInMbSettingLowerDefault < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup to avoid running the migration
    return if !Setting.exists?(name: 'system_init_done')

    # don't change non default/custom value
    return if Setting.get('es_attachment_max_size_in_mb') != 50

    # set new default value
    Setting.set('es_attachment_max_size_in_mb', 10)
  end
end

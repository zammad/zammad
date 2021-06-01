# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2641KbColorChangeLimit < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_column :knowledge_bases, :color_highlight, :string, limit: 25
    change_column :knowledge_bases, :color_header,    :string, limit: 25
  end
end

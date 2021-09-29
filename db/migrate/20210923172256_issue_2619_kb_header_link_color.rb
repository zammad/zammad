# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2619KbHeaderLinkColor < ActiveRecord::Migration[6.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    add_column :knowledge_bases, :color_header_link, :string, limit: 25, null: false, default: 'hsl(206,8%,50%)' # rubocop:disable Zammad/ExistsResetColumnInformation
    change_column_default :knowledge_bases, :color_header_link, nil
    KnowledgeBase.reset_column_information
  end
end

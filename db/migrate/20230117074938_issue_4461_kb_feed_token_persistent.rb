# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4461KbFeedTokenPersistent < ActiveRecord::Migration[6.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Token
      .where(action: 'KnowledgeBaseFeed', persistent: false)
      .update(persistent: true)
  end
end

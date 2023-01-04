# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AddTicketArticleTypeFacebookDirectMessage < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Ticket::Article::Type.create_if_not_exists(
      name:          'facebook direct-message',
      communication: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end

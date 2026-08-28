# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CleanupOrphanedCtiCallerIds < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Cti::CallerId.add stores the *article* ID as o_id for object: 'Ticket' rows
    # (see app/models/cti/caller_id.rb). Historically, Ticket::Article#destroy did not
    # clean these up, so deleted tickets/articles (e.g. via data privacy deletion)
    # left orphaned rows with phone numbers behind.
    # https://github.com/zammad/zammad/issues/6324
    Cti::CallerId.where(object: 'Ticket')
                 .joins('LEFT OUTER JOIN ticket_articles ON ticket_articles.id = cti_caller_ids.o_id')
                 .where(ticket_articles: { id: nil })
                 .delete_all
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CleanupOrphanedCtiCallerIds, :aggregate_failures, type: :db_migration do
  let!(:ticket) { create(:ticket) }

  let!(:article)   { create(:ticket_article, ticket: ticket) }
  let!(:caller_id) { create(:cti_caller_id, object: 'Ticket', o_id: article.id) }

  let!(:live_article)   { create(:ticket_article, ticket: ticket) }
  let!(:live_caller_id) { create(:cti_caller_id, object: 'Ticket', o_id: live_article.id) }

  it 'removes caller ID rows orphaned by an article deleted without cleanup, but keeps rows with a live article' do
    Ticket::Article.where(id: article.id).delete_all

    migrate

    expect(Cti::CallerId).not_to exist(caller_id.id)
    expect(Cti::CallerId).to exist(live_caller_id.id)
  end
end

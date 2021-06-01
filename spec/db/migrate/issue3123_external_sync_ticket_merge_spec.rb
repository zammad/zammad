# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3123ExternalSyncTicketMerge, type: :db_migration do

  let(:user) { create(:agent) }
  let(:source_ticket) { create(:ticket) }
  let(:target_ticket) { create(:ticket) }

  before do
    source_ticket.merge_to(
      ticket_id: target_ticket.id,
      user_id:   user.id,
    )
  end

  context 'when no ExternalSync entries' do

    it "doesn't send ExternalSync.migrate" do
      allow(ExternalSync).to receive(:migrate)
      migrate
      expect(ExternalSync).not_to have_received(:migrate)
    end
  end

  context 'when ExternalSync entries present' do

    before do
      create(:external_sync, object: 'Ticket', o_id: source_ticket.id)
    end

    it 'sends ExternalSync.migrate' do
      allow(ExternalSync).to receive(:migrate)
      migrate
      expect(ExternalSync).to have_received(:migrate).with('Ticket', source_ticket.id, target_ticket.id)
    end
  end
end

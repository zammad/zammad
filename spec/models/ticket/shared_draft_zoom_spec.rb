# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::SharedDraftZoom, type: :model do
  subject(:shared_draft_zoom) { create(:ticket_shared_draft_zoom) }

  it { is_expected.to belong_to :ticket }
  it { expect(shared_draft_zoom.new_article).to be_a(Hash) }
  it { expect(shared_draft_zoom.ticket_attributes).to be_a(Hash) }

  describe 'Draft Sharing: Add history entry for updating and deleting of a draft #3983' do
    it 'does create a history entry for the new draft' do
      expect(shared_draft_zoom.ticket.history_get)
        .to include(include('object' => 'Ticket::SharedDraftZoom', 'type' => 'created'))
    end

    it 'does add a history entry for removing the draft' do
      shared_draft_zoom.destroy

      expect(shared_draft_zoom.ticket.history_get)
        .to include(include('object' => 'Ticket::SharedDraftZoom', 'type' => 'removed'))
    end
  end
end

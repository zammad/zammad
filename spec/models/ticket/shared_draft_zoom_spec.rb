# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::SharedDraftZoom, type: :model do
  subject(:shared_draft_zoom) { create :ticket_shared_draft_zoom }

  it { is_expected.to belong_to :ticket }
  it { expect(shared_draft_zoom.new_article).to be_a(Hash) }
  it { expect(shared_draft_zoom.ticket_attributes).to be_a(Hash) }
end

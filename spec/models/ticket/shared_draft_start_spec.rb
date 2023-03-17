# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::SharedDraftStart, type: :model do
  subject(:shared_draft_start) { create(:ticket_shared_draft_start) }

  it { is_expected.to belong_to :group }
  it { is_expected.to validate_presence_of :name }
  it { expect(shared_draft_start.content).to be_a(Hash) }
end

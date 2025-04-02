# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::SharedDraft::Zoom::Update do
  let(:user)              { create(:agent) }
  let(:ticket)            { create(:ticket) }
  let(:shared_draft)      { create(:ticket_shared_draft_zoom, ticket: ticket) }
  let(:form_id)           { 123 }
  let(:new_article)       { { new_article: false } }
  let(:ticket_attributes) { { ticket_attributes: false } }

  context 'when user has insufficient acces to the draft related ticket' do
    it 'raises an error' do
      expect do
        described_class
          .new(user, form_id, shared_draft, new_article:, ticket_attributes:)
          .execute
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when user has sufficient access to the draft related ticket' do
    before do
      user.user_groups.create! group: ticket.group, access: :full
    end

    it 'updates the shared draft' do
      described_class
        .new(user, form_id, shared_draft, new_article:, ticket_attributes:)
        .execute

      expect(shared_draft.reload.new_article.symbolize_keys).to eq(new_article)
    end

    it 'copies attachments from the given form' do
      create(:store, o_id: form_id)

      draft = described_class
        .new(user, form_id, shared_draft, new_article:, ticket_attributes:)
        .execute

      expect(Store.list(object: draft.class.name, o_id: draft.id))
        .to contain_exactly(have_attributes(filename: 'test.txt'))
    end
  end
end

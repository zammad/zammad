# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::SharedDraft::Start::Create do
  let(:group)   { create(:group) }
  let(:content) { { content: Faker::Lorem.unique.sentence } }
  let(:name)    { Faker::Lorem.unique.sentence }
  let(:form_id) { 123 }

  let(:user) do
    create(:agent)
      .tap { |elem| elem.user_groups.create!(group:, access: :create) }
  end

  context 'when user has access to the draft group' do
    it 'returns new object' do
      draft = described_class
        .new(user, form_id, name:, content:, group:)
        .execute

      expect(draft).to have_attributes(name:, content:, group:)
    end

    it 'copies attachments from the given form' do
      create(:store, o_id: form_id)

      draft = described_class
        .new(user, form_id, name:, content:, group:)
        .execute

      expect(Store.list(object: draft.class.name, o_id: draft.id))
        .to contain_exactly(have_attributes(filename: 'test.txt'))
    end

    it 'copies inline attachment and keeps it inline' do
      content = attributes_for(:ticket_shared_draft_start, :with_inline_image)[:content]

      draft = described_class
        .new(user, form_id, name:, content:, group:)
        .execute

      expect(Store.list(object: draft.class.name, o_id: draft.id))
        .to contain_exactly(have_attributes(
                              filename:    'image1.jpeg',
                              preferences: include('Content-Disposition' => 'inline')
                            ))
    end
  end

  context 'when user has insufficient access to the draft group' do
    before do
      allow(user).to receive(:group_access?).with(group.id, :create).and_return(false)
    end

    it 'raises an error' do
      expect do
        described_class
          .new(user, form_id, name:, content:, group:)
          .execute
      end
        .to raise_error(Pundit::NotAuthorizedError)
    end
  end

end

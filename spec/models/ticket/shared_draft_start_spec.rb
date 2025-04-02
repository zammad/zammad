# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::SharedDraftStart, current_user_id: 1, type: :model do
  subject(:shared_draft_start) { create(:ticket_shared_draft_start, :with_inline_image) }

  it { is_expected.to belong_to :group }
  it { is_expected.to validate_presence_of :name }
  it { expect(shared_draft_start.content).to be_a(Hash) }

  describe '#clear_group_id' do
    it 'removes group ID from content' do
      shared_draft_start.content['group_id'] = 'test group id'
      shared_draft_start.save!

      expect(shared_draft_start.content).not_to have_key('group_id')
    end
  end

  describe '#trigger_subscriptions' do
    it 'triggers subscription when draft is created' do
      allow(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup)
        .to receive(:trigger)

      shared_draft_start

      expect(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup).to have_received(:trigger)
        .with(be_nil,
              arguments: include(
                group_id: Gql::ZammadSchema.id_from_object(shared_draft_start.group)
              ))
    end

    it 'triggers subscription when draft is updated' do
      shared_draft_start

      allow(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup)
        .to receive(:trigger)

      shared_draft_start.touch

      expect(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup).to have_received(:trigger)
        .with(be_nil,
              arguments: include(
                group_id: Gql::ZammadSchema.id_from_object(shared_draft_start.group)
              ))
    end

    it 'triggers subscription twice when draft group is changed', aggregate_failures: true do
      shared_draft_start

      allow(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup)
        .to receive(:trigger)

      old_group = shared_draft_start.group

      shared_draft_start.update! group: create(:group)

      expect(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup).to have_received(:trigger)
        .with(be_nil,
              arguments: include(
                group_id: Gql::ZammadSchema.id_from_object(shared_draft_start.group)
              ))

      expect(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup).to have_received(:trigger)
        .with(be_nil,
              arguments: include(
                group_id: Gql::ZammadSchema.id_from_object(old_group)
              ))
    end

    it 'triggers subscription when draft is destroyed' do
      shared_draft_start

      allow(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup)
        .to receive(:trigger)

      shared_draft_start.destroy

      expect(Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup).to have_received(:trigger)
        .with(be_nil,
              arguments: include(
                group_id: Gql::ZammadSchema.id_from_object(shared_draft_start.group)
              ))
    end
  end

  describe '#body' do
    let(:test) { Faker::Lorem.sentence }

    it 'reads value from content' do
      shared_draft_start.content[:body] = test

      expect(shared_draft_start.body).to eq(test)
    end

    it 'sets value to content' do
      shared_draft_start.body = test

      expect(shared_draft_start.content).to include(body: test, title: '123')
    end
  end

  describe '#body_with_base64' do
    it 'returns inline images in base64' do
      expect(shared_draft_start.body_with_base64).to start_with('text and <img src="data:image/jpeg;base64,')
    end
  end

  describe '#content_with_base64' do
    it 'returns inline images in base64' do
      expect(shared_draft_start.content_with_base64)
        .to include(body: start_with('text and <img src="data:image/jpeg;base64,'))
    end
  end

  describe '#content_with_body_urls' do
    it 'returns inline images with URLs' do
      expect(shared_draft_start.content_with_body_urls)
        .to include(body: start_with('text and <img src="/api/v1/attachments'))
    end
  end

  describe '#content_with_form_id_body_urls' do
    let(:new_form_id) { '123' }

    it 'returns inline images referencing copied assets' do
      shared_draft_start.clone_attachments('UploadCache', new_form_id)

      new_attachments = Store.list(object: 'UploadCache', o_id: new_form_id)

      expect(shared_draft_start.content_with_form_id_body_urls(new_form_id)).to include(
        body: start_with("text and <img src=\"/api/v1/attachments/#{new_attachments.last.id}")
      )
    end
  end
end

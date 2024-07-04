# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::SharedDraftStart, type: :model do
  subject(:shared_draft_start) { create(:ticket_shared_draft_start) }

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
end

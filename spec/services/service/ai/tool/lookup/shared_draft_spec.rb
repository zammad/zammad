# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Lookup::SharedDraft, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:, pending_time: Time.zone.parse('2026-11-05 10:00')) }

  def draft(ticket_attributes)
    UserInfo.with_user_id(agent.id) do
      ticket.create_shared_draft!(new_article: { 'type' => 'note', 'body' => 'A note.' }, ticket_attributes:)
    end
  end

  describe '.of' do
    it 'finds the draft where the group has shared drafts and the user may change the ticket' do
      saved = draft({})

      expect(described_class.of(ticket, user: agent)).to eq(saved)
      expect(described_class.of(ticket, user: create(:agent))).to be_nil

      group.update!(shared_drafts: false)
      expect(described_class.of(ticket.reload, user: agent)).to be_nil
    end
  end

  describe '.changed_fields' do
    it 'takes an empty owner for nobody, as both forms send it' do
      expect(ticket.owner_id).to eq(1)
      expect(described_class.changed_fields(draft({ 'owner_id' => '' }))).to be_empty
      expect(described_class.changed_fields(draft({ 'owner_id' => nil }))).to be_empty
      expect(described_class.changed_fields(draft({ 'owner_id' => agent.id.to_s }))).to eq(['owner_id'])
    end

    it 'names only the ticket fields whose value the draft changes, however the form writes it' do
      unchanged = {
        'state_id'                  => ticket.state_id.to_s,
        'priority_id'               => ticket.priority_id,
        'pending_time'              => '2026-11-05T10:00:00.000Z',
        'title'                     => ticket.title,
        'isDefaultFollowUpStateSet' => true,
        'id'                        => Gql::ZammadSchema.id_from_object(ticket),
      }

      expect(described_class.changed_fields(draft(unchanged))).to be_empty
      expect(described_class.changed_fields(draft(unchanged.merge('priority_id' => '3', 'pending_time' => '2026-11-06T10:00:00.000Z')))).to contain_exactly('priority_id', 'pending_time')
    end
  end
end

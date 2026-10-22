# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActivityStream::Assets do
  describe '#assets' do
    subject(:assets) { UserInfo.with_user_id(agent.id) { activity_stream.reload.assets({}) } }

    let(:group)           { create(:group) }
    let(:agent)           { create(:agent, groups: [group]) }
    let(:ticket)          { create(:ticket, group: group) }
    let(:creator)         { create(:customer) }
    let(:activity_stream) { create(:activity_stream, o: ticket, created_by_id: creator.id) }

    # What deleting the creator leaves behind when its cache clear misses the cached entry.
    context 'when the creator was replaced without touching the entry' do
      before do
        activity_stream.attributes_with_association_ids
        ActivityStream.where(id: activity_stream.id).update_all(created_by_id: 1)
      end

      it 'ships the entry with its current creator' do
        expect(assets[:ActivityStream][activity_stream.id]).to include('created_by_id' => 1)
      end

      it 'ships no assets of the replaced creator' do
        expect(assets[:User]).not_to have_key(creator.id)
      end
    end
  end
end

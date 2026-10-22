# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OnlineNotification::Assets do
  describe '#assets' do
    subject(:assets) { UserInfo.with_user_id(agent.id) { notification.reload.assets({}) } }

    let(:group)        { create(:group) }
    let(:agent)        { create(:agent, groups: [group]) }
    let(:ticket)       { create(:ticket, group: group) }
    let(:creator)      { create(:customer) }
    let(:notification) { create(:online_notification, o: ticket, user_id: agent.id, created_by_id: creator.id, updated_by_id: creator.id) }

    # What deleting the creator leaves behind when its cache clear misses the cached notification.
    context 'when the creator was replaced without touching the notification' do
      before do
        notification.attributes_with_association_ids
        OnlineNotification.where(id: notification.id).update_all(created_by_id: 1, updated_by_id: 1)
      end

      it 'ships the notification with its current creator' do
        expect(assets[:OnlineNotification][notification.id]).to include('created_by_id' => 1, 'updated_by_id' => 1)
      end

      it 'ships no assets of the replaced creator' do
        expect(assets[:User]).not_to have_key(creator.id)
      end
    end
  end
end

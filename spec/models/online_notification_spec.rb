# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe OnlineNotification, type: :model do
  subject(:online_notification) { create(:online_notification, o: ticket) }

  let(:ticket) { create(:ticket) }

  it_behaves_like 'ApplicationModel'

  describe '#related_object' do
    it 'returns ticket' do
      expect(online_notification.related_object).to eq ticket
    end
  end

  describe '.list' do
    let(:user)           { create(:agent, groups: [group]) }
    let(:another_user)   { create(:agent, groups: [group]) }
    let(:group)          { create(:group) }
    let(:ticket)         { create(:ticket, group: group) }
    let(:another_ticket) { create(:ticket, group: group) }
    let(:notification_1) { create(:online_notification, o: ticket, user: user) }
    let(:notification_2) { create(:online_notification, o: ticket, user: another_user) }
    let(:notification_3) { create(:online_notification, o: another_ticket, user: user) }

    before do
      notification_1 && notification_2 && notification_3
    end

    it 'returns notifications for a given user' do
      expect(described_class.list(user))
        .to contain_exactly(notification_1, notification_3)
    end

    context 'when user looses access to one of the referenced tickets' do
      before do
        another_ticket.update! group: create(:group)
      end

      it 'with ensure_access flag it returns notifications given user has access to' do
        expect(described_class.list(user, access: 'full'))
          .to contain_exactly(notification_1)
      end

      it 'without ensure_access flag it returns all notifications given user has' do
        expect(described_class.list(user, access: 'ignore'))
          .to contain_exactly(notification_1, notification_3)
      end
    end
  end
end

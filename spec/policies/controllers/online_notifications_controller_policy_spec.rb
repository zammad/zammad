# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Controllers::OnlineNotificationsControllerPolicy, current_user_id: 1 do
  subject { described_class.new(user, record) }

  let(:group_with_access)    { create(:group) }
  let(:group_without_access) { create(:group) }
  let(:user)                 { create(:agent, groups: [group_with_access]) }
  let(:ticket)               { create(:ticket, group: group_with_access) }
  let(:online_notification)  { create(:online_notification, o: ticket, user: notified_user) }
  let(:notified_user)        { user }

  let(:record) do
    rec        = OnlineNotificationsController.new
    rec.params = { id: online_notification.id }
    rec
  end

  context 'when the notification belongs to the user' do
    context 'when the related ticket is accessible' do
      it { is_expected.to permit_actions(:show, :update, :destroy) }
    end

    context 'when the related ticket was moved to an inaccessible group' do
      before { ticket.update!(group: group_without_access) }

      it { is_expected.to forbid_actions(:show, :update) }
      it { is_expected.to permit_actions(:destroy) }
    end

    context 'when the group permissions were revoked' do
      before do
        user.group_ids = []
        user.save!
      end

      it { is_expected.to forbid_actions(:show, :update) }
      it { is_expected.to permit_actions(:destroy) }
    end
  end

  context 'when the notification belongs to another user' do
    let(:notified_user) { create(:agent, groups: [group_with_access]) }

    it { is_expected.to forbid_actions(:show, :update, :destroy) }
  end
end

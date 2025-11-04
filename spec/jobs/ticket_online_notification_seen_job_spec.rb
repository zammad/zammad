# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketOnlineNotificationSeenJob, type: :job do
  let(:group)      { create(:group) }
  let(:user)       { create(:agent, groups: [group]) }
  let(:other_user) { create(:agent, groups: [group]) }
  let(:ticket)     { create(:ticket, owner: user, group: group) }
  let(:online_notification) do
    create(:online_notification, o_id: ticket.id, user_id: user.id)
  end

  it 'checks if online notification has not been seen' do
    expect(online_notification.reload.seen).to be false
  end

  it 'checks if online notification has been seen', current_user_id: -> { user.id } do
    ticket.state_id = Ticket::State.lookup(name: 'closed').id
    ticket.save!

    expect do
      described_class.perform_now(ticket.id, user.id)
    end.to change { online_notification.reload.seen }
  end

  context 'when some ticket subscribers exists for the ticket' do
    before do
      create(:mention, mentionable: ticket, user: other_user)
    end

    it 'does not mark online notifications as seen for mentioned users' do
      # Create an online notification for the mentioned user on the same ticket
      mentioned_notification = create(:online_notification, o_id: ticket.id, user_id: other_user.id)

      # Move ticket to a state that would normally auto-mark notifications as seen
      ticket.update!(state_id: Ticket::State.lookup(name: 'closed').id)

      # Ensure the mentioned user's notification is NOT auto-marked as seen
      expect { described_class.perform_now(ticket.id, user.id) }
        .not_to change { mentioned_notification.reload.seen }.from(false)
    end
  end
end

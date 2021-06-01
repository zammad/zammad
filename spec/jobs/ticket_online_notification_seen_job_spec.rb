# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketOnlineNotificationSeenJob, type: :job do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:ticket) { create(:ticket, owner: user, created_by_id: user.id) }
  let!(:online_notification) do
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
end

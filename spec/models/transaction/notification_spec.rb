# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Transaction::Notification, type: :model do
  describe 'pending ticket reminder repeats after midnight at selected time zone' do
    let(:group)  { create(:group) }
    let(:user)   { create(:agent) }
    let(:ticket) { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }

    before do
      travel_to Time.current.noon
      user.groups << group
      ticket

      Setting.set('timezone_default', 'America/Santiago')
      run(ticket, user, 'reminder_reached')
      OnlineNotification.destroy_all
    end

    it 'notification not sent at UTC midnight' do
      travel_to Time.current.end_of_day + 1.minute

      expect { run(ticket, user, 'reminder_reached') }.not_to change(OnlineNotification, :count)
    end

    it 'notification sent at selected time zone midnight' do
      travel_to Time.use_zone('America/Santiago') { Time.current.end_of_day + 1.minute }

      expect { run(ticket, user, 'reminder_reached') }.to change(OnlineNotification, :count).by(1)
    end
  end

  def run(ticket, user, type)
    described_class.new(
      object:           ticket.class.name,
      type:             type,
      object_id:        ticket.id,
      interface_handle: 'scheduler',
      changes:          nil,
      created_at:       Time.current,
      user_id:          user.id
    ).perform
  end
end

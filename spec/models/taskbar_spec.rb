require 'rails_helper'

RSpec.describe Taskbar do

  context 'single creation' do
    Taskbar.destroy_all
    UserInfo.current_user_id = 1

    taskbar = Taskbar.create(
      client_id: 123,
      key: 'Ticket-1234',
      callback: 'TicketZoom',
      params: {
        id: 1234,
      },
      state: {},
      prio: 1,
      notify: false,
    )

    it 'existing key' do
      expect(taskbar.key).to eq('Ticket-1234')
    end

    it 'params' do
      expect(taskbar.params[:id]).to eq(1234)
    end

    it 'state' do
      expect(taskbar.state.blank?).to eq(true)
    end

    it 'check last_contact' do
      UserInfo.current_user_id = 1

      last_contact1 = taskbar.last_contact

      travel 2.minutes
      taskbar.notify = false
      taskbar.state = { a: 1 }
      taskbar.save!
      expect(taskbar.last_contact.to_s).not_to eq(last_contact1.to_s)

      last_contact2 = taskbar.last_contact
      travel 2.minutes
      taskbar.notify = true
      taskbar.save!
      expect(taskbar.last_contact.to_s).not_to eq(last_contact1.to_s)
      expect(taskbar.last_contact.to_s).to eq(last_contact2.to_s)

      travel 2.minutes
      taskbar.notify = true
      taskbar.save!

      expect(taskbar.last_contact.to_s).not_to eq(last_contact1.to_s)
      expect(taskbar.last_contact.to_s).to eq(last_contact2.to_s)

      travel 2.minutes
      taskbar.notify = false
      taskbar.state = { a: 1 }
      taskbar.save!

      expect(taskbar.last_contact.to_s).not_to eq(last_contact1.to_s)
      expect(taskbar.last_contact.to_s).to eq(last_contact2.to_s)

      travel 2.minutes
      taskbar.notify = true
      taskbar.state = { a: 1 }
      taskbar.save!

      expect(taskbar.last_contact.to_s).not_to eq(last_contact1.to_s)
      expect(taskbar.last_contact.to_s).to eq(last_contact2.to_s)

      travel 2.minutes
      taskbar.notify = true
      taskbar.state = { a: 2 }
      taskbar.save!

      expect(taskbar.last_contact.to_s).not_to eq(last_contact1.to_s)
      expect(taskbar.last_contact.to_s).not_to eq(last_contact2.to_s)
    end

    UserInfo.current_user_id = nil
  end

  context 'multible creation' do

    it 'create tasks' do

      Taskbar.destroy_all
      UserInfo.current_user_id = 1
      taskbar1 = Taskbar.create(
        client_id: 123,
        key: 'Ticket-1234',
        callback: 'TicketZoom',
        params: {
          id: 1234,
        },
        state: {},
        prio: 1,
        notify: false,
      )

      UserInfo.current_user_id = 2
      taskbar2 = Taskbar.create(
        client_id: 123,
        key: 'Ticket-1234',
        callback: 'TicketZoom',
        params: {
          id: 1234,
        },
        state: {},
        prio: 2,
        notify: false,
      )

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(2)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(2)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(false)

      taskbar3 = Taskbar.create(
        client_id: 123,
        key: 'Ticket-4444',
        callback: 'TicketZoom',
        params: {
          id: 4444,
        },
        state: {},
        prio: 2,
        notify: false,
      )

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(2)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(2)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)

      UserInfo.current_user_id = 3
      taskbar4 = Taskbar.create(
        client_id: 123,
        key: 'Ticket-1234',
        callback: 'TicketZoom',
        params: {
          id: 1234,
        },
        state: {},
        prio: 4,
        notify: false,
      )

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar1.preferences[:tasks][2][:changed]).to eq(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar2.preferences[:tasks][2][:changed]).to eq(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar4.preferences[:tasks][2][:changed]).to eq(false)

      UserInfo.current_user_id = 2
      taskbar2.state = { article: {}, ticket: {} }
      taskbar2.save!

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar1.preferences[:tasks][2][:changed]).to eq(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar2.preferences[:tasks][2][:changed]).to eq(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar4.preferences[:tasks][2][:changed]).to eq(false)

      UserInfo.current_user_id = 2
      taskbar2.state = { article: { body: 'some body' }, ticket: {} }
      taskbar2.save!

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar1.preferences[:tasks][2][:changed]).to eq(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar2.preferences[:tasks][2][:changed]).to eq(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar4.preferences[:tasks][2][:changed]).to eq(false)

      UserInfo.current_user_id = 1
      taskbar1.state = { article: { body: '' }, ticket: { state_id: 123 } }
      taskbar1.save!

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar1.preferences[:tasks][2][:changed]).to eq(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar2.preferences[:tasks][2][:changed]).to eq(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar4.preferences[:tasks][2][:changed]).to eq(false)

      taskbar1_last_contact = taskbar1.last_contact.to_s
      taskbar2_last_contact = taskbar2.last_contact.to_s
      taskbar3_last_contact = taskbar3.last_contact.to_s
      taskbar4_last_contact = taskbar4.last_contact.to_s
      travel 2.minutes

      UserInfo.current_user_id = 2
      taskbar2.state = { article: { body: 'some body' }, ticket: {} }
      taskbar2.notify = true
      taskbar2.save!

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][1][:last_contact].to_s).to eq(taskbar2_last_contact)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar1.preferences[:tasks][2][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][2][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][1][:last_contact].to_s).to eq(taskbar2_last_contact)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar2.preferences[:tasks][2][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][2][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar3.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar3_last_contact)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][1][:last_contact].to_s).to eq(taskbar2_last_contact)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar4.preferences[:tasks][2][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][2][:last_contact].to_s).to eq(taskbar4_last_contact)

      UserInfo.current_user_id = 2
      taskbar2.state = { article: { body: 'some body 222' }, ticket: {} }
      taskbar2.notify = true
      taskbar2.save!

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar1.preferences[:tasks][1][:last_contact].to_s).not_to eq(taskbar2_last_contact)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar1.preferences[:tasks][2][:changed]).to eq(false)
      expect(taskbar1.preferences[:tasks][2][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar2.preferences[:tasks][1][:last_contact].to_s).not_to eq(taskbar2_last_contact)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar2.preferences[:tasks][2][:changed]).to eq(false)
      expect(taskbar2.preferences[:tasks][2][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:changed]).to eq(false)
      expect(taskbar3.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar3_last_contact)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][0][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:changed]).to eq(true)
      expect(taskbar4.preferences[:tasks][1][:last_contact].to_s).not_to eq(taskbar2_last_contact)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(3)
      expect(taskbar4.preferences[:tasks][2][:changed]).to eq(false)
      expect(taskbar4.preferences[:tasks][2][:last_contact].to_s).to eq(taskbar4_last_contact)

      travel_back

      UserInfo.current_user_id = nil
    end
  end

end

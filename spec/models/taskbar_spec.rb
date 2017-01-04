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
      expect(taskbar.state.empty?).to eq(true)
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

      UserInfo.current_user_id = nil
    end
  end

end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/taskbar/has_attachments_examples'
require 'models/taskbar/list_examples'

RSpec.describe Taskbar, performs_jobs: true, type: :model do
  it_behaves_like 'Taskbar::HasAttachments'
  it_behaves_like 'Taskbar::List'

  context 'item' do
    subject(:taskbar) { create(:taskbar) }

    it { is_expected.to validate_inclusion_of(:app).in_array(%w[desktop mobile]) }

    it do
      if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'
        expect(taskbar).to validate_uniqueness_of(:key).scoped_to(%w[user_id app]).with_message(%r{}).case_insensitive
      else
        expect(taskbar).to validate_uniqueness_of(:key).scoped_to(%w[user_id app]).with_message(%r{})
      end
    end
  end

  context 'single creation' do

    let(:taskbar) do

      described_class.destroy_all
      UserInfo.current_user_id = 1

      create(:taskbar, params: { id: 1234 }, key: 'Ticket-1234')
    end

    it 'existing key' do
      expect(taskbar.key).to eq('Ticket-1234')
    end

    it 'params' do
      expect(taskbar.params[:id]).to eq(1234)
    end

    it 'state' do
      expect(taskbar.state.blank?).to be(true)
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
  end

  context 'multiple creation', :aggregate_failures do

    it 'create tasks' do
      # skip 'What does this test?'

      described_class.destroy_all
      UserInfo.current_user_id = 1
      taskbar1 = described_class.create!(
        key:      'Ticket-1234',
        callback: 'TicketZoom',
        params:   {
          id: 1234,
        },
        state:    {},
        prio:     1,
        notify:   false,
        user_id:  1,
      )

      UserInfo.current_user_id = 2
      taskbar2 = described_class.create!(
        key:      'Ticket-1234',
        callback: 'TicketZoom',
        params:   {
          id: 1234,
        },
        state:    {},
        prio:     2,
        notify:   false,
        user_id:  1,
      )

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(2)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(2)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)

      taskbar3 = described_class.create(
        key:      'Ticket-4444',
        callback: 'TicketZoom',
        params:   {
          id: 4444,
        },
        state:    {},
        prio:     2,
        notify:   false,
        user_id:  1,
      )

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(2)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(2)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)

      agent_id = create(:agent).id
      UserInfo.current_user_id = agent_id

      taskbar4 = described_class.create(
        key:      'Ticket-1234',
        callback: 'TicketZoom',
        params:   {
          id: 1234,
        },
        state:    {},
        prio:     4,
        notify:   false,
        user_id:  1,
      )

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      UserInfo.current_user_id = 2
      taskbar2.state = { article: {}, ticket: {} }
      taskbar2.save!

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      UserInfo.current_user_id = 2
      taskbar2.state = { article: { body: 'some body' }, ticket: {} }
      taskbar2.save!

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      UserInfo.current_user_id = 1
      taskbar1.state = { article: { body: '' }, ticket: { state_id: 123 } }
      taskbar1.save!

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)

      taskbar1_last_contact = taskbar1.last_contact.to_s
      taskbar2_last_contact = taskbar2.last_contact.to_s
      taskbar3_last_contact = taskbar3.last_contact.to_s
      taskbar4_last_contact = taskbar4.last_contact.to_s
      travel 2.minutes

      UserInfo.current_user_id = 2
      taskbar2.state = { article: { body: 'some body' }, ticket: {} }
      taskbar2.notify = true
      taskbar2.save!

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:last_contact].to_s).to eq(taskbar2_last_contact)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:last_contact].to_s).to eq(taskbar2_last_contact)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar3_last_contact)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:last_contact].to_s).to eq(taskbar2_last_contact)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:last_contact].to_s).to eq(taskbar4_last_contact)

      UserInfo.current_user_id = 2
      taskbar2.state = { article: { body: 'some body 222' }, ticket: {} }
      taskbar2.notify = true
      taskbar2.save!

      perform_enqueued_jobs

      taskbar1.reload
      expect(taskbar1.preferences[:tasks].count).to eq(3)
      expect(taskbar1.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar1.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar1.preferences[:tasks][1][:apps][:desktop][:last_contact].to_s).not_to eq(taskbar2_last_contact)
      expect(taskbar1.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)
      expect(taskbar1.preferences[:tasks][2][:apps][:desktop][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar2.reload
      expect(taskbar2.preferences[:tasks].count).to eq(3)
      expect(taskbar2.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar2.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar2.preferences[:tasks][1][:apps][:desktop][:last_contact].to_s).not_to eq(taskbar2_last_contact)
      expect(taskbar2.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)
      expect(taskbar2.preferences[:tasks][2][:apps][:desktop][:last_contact].to_s).to eq(taskbar4_last_contact)

      taskbar3.reload
      expect(taskbar3.preferences[:tasks].count).to eq(1)
      expect(taskbar3.preferences[:tasks][0][:user_id]).to eq(2)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:changed]).to be(false)
      expect(taskbar3.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar3_last_contact)

      taskbar4.reload
      expect(taskbar4.preferences[:tasks].count).to eq(3)
      expect(taskbar4.preferences[:tasks][0][:user_id]).to eq(1)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][0][:apps][:desktop][:last_contact].to_s).to eq(taskbar1_last_contact)
      expect(taskbar4.preferences[:tasks][1][:user_id]).to eq(2)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:changed]).to be(true)
      expect(taskbar4.preferences[:tasks][1][:apps][:desktop][:last_contact].to_s).not_to eq(taskbar2_last_contact)
      expect(taskbar4.preferences[:tasks][2][:user_id]).to eq(agent_id)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:changed]).to be(false)
      expect(taskbar4.preferences[:tasks][2][:apps][:desktop][:last_contact].to_s).to eq(taskbar4_last_contact)

      travel_back

      UserInfo.current_user_id = nil
    end
  end

  describe '#preferences_task_info' do
    it 'returns task info for an existing taskbar without changes' do
      taskbar = create(:taskbar)

      expect(taskbar.preferences_task_info)
        .to eq({
                 id: taskbar.id, user_id: 1, apps: { desktop: { last_contact: taskbar.last_contact, changed: false } }
               })
    end

    it 'returns task info for an existing taskbar with changes' do
      taskbar = create(:taskbar, state: { a: 123 })

      expect(taskbar.preferences_task_info)
        .to eq({
                 id: taskbar.id, user_id: 1, apps: { desktop: { last_contact: taskbar.last_contact, changed: true } }
               })
    end

    it 'returns task info for a new taskbar' do
      taskbar = build(:taskbar)

      expect(taskbar.preferences_task_info)
        .to eq({
                 user_id: 1, apps: { desktop: { last_contact: taskbar.last_contact, changed: false } }
               })
    end

    it 'returns task info for an existing taskbar without changes (form_id only)' do
      taskbar = create(:taskbar, state: { form_id: SecureRandom.uuid })

      expect(taskbar.preferences_task_info)
        .to eq({
                 id: taskbar.id, user_id: 1, apps: { desktop: { last_contact: taskbar.last_contact, changed: false } }
               })
    end

    it 'returns task info for an existing taskbar without changes (nested form_id only)' do
      taskbar = create(:taskbar, state: { article: { form_id: SecureRandom.uuid } })

      expect(taskbar.preferences_task_info)
        .to eq({
                 id: taskbar.id, user_id: 1, apps: { desktop: { last_contact: taskbar.last_contact, changed: false } }
               })
    end
  end

  describe '#update_preferences_infos' do
    it 'do not process search taskbars' do
      taskbar = build(:taskbar, key: 'Search')

      allow(taskbar).to receive(:collect_related_tasks)
      taskbar.save
      expect(taskbar).not_to have_received(:collect_related_tasks)
    end

    it 'do not process items with local_update flag' do
      taskbar = create(:taskbar)

      allow(taskbar).to receive(:collect_related_tasks)
      taskbar.state = { a: 'b' }
      taskbar.local_update = true
      taskbar.save
      expect(taskbar).not_to have_received(:collect_related_tasks)
    end

    context 'with other taskbars' do
      let(:key)           { Random.hex }
      let(:other_user)    { create(:user) }
      let(:other_taskbar) { create(:taskbar, key: key, user: other_user) }

      before { other_taskbar }

      it 'sets tasks when creating a taskbar' do
        taskbar = create(:taskbar, key: key)

        expect(taskbar.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: 1))
      end

      it 'updates related items when creating a taskbar' do
        create(:taskbar, key: key)
        perform_enqueued_jobs

        expect(other_taskbar.reload.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: 1))
      end

      it 'sets tasks when updating a taskbar' do
        taskbar = create(:taskbar, key: key)
        taskbar.update_columns preferences: {}

        taskbar.update! state: { a: :b }

        expect(taskbar.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: 1))
      end

      it 'sets tasks when updating a taskbar with same user but different app' do
        taskbar = create(:taskbar, key: key, user: other_user, app: 'mobile')
        taskbar.update_columns preferences: {}

        taskbar.update! state: { a: :b }

        expect(taskbar.preferences[:tasks])
          .to include(include(user_id: other_user.id, apps: have_key(:desktop).and(have_key(:mobile))))
      end

      it 'updates related items when updating a taskbar' do
        taskbar = create(:taskbar, key: key)

        other_taskbar.update_columns preferences: {}

        taskbar.update! state: { a: :b }

        perform_enqueued_jobs

        expect(other_taskbar.reload.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: 1))
      end

      it 'updates related items when destroying a taskbar' do
        taskbar = create(:taskbar, key: key)
        taskbar.destroy!

        expect(other_taskbar.reload.preferences[:tasks]).to include(include(user_id: other_user.id))
      end
    end
  end

  describe '#collect_related_tasks' do
    let(:key)       { Random.hex }
    let(:taskbar_1) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_2) { create(:taskbar, key: key, user: create(:user)) }

    before { taskbar_2 }

    it 'returns tasks for self and related items' do
      expect(taskbar_1.send(:collect_related_tasks))
        .to eq([taskbar_2.preferences_task_info, taskbar_1.preferences_task_info])
    end

    it 'returns tasks for a new taskbar' do
      new_taskbar = build(:taskbar, key: key)

      expect(new_taskbar.send(:collect_related_tasks))
        .to eq([taskbar_2.preferences_task_info, new_taskbar.preferences_task_info])
    end

    it 'do not include task of the destroyed taskbar' do
      taskbar_1

      taskbar_2.destroy!

      expect(taskbar_2.send(:collect_related_tasks))
        .to eq([taskbar_1.preferences_task_info])
    end
  end

  describe '#reduce_related_tasks' do
    let(:elem) { { user_id: 123, changed: { desktop: false } } }
    let(:memo) { {} }

    it 'adds new task details' do
      taskbar = create(:taskbar)

      taskbar.send(:reduce_related_tasks, elem, memo)

      expect(memo).to include(elem[:user_id] => include(changed: include(desktop: false)))
    end

    it 'extends existing task details with additional apps' do
      taskbar = create(:taskbar)

      another_elem = { user_id: 123, changed: { mobile: true } }

      taskbar.send(:reduce_related_tasks, elem, memo)
      taskbar.send(:reduce_related_tasks, another_elem, memo)

      expect(memo).to include(elem[:user_id] => include(changed: include(desktop: false, mobile: true)))
    end
  end

  describe '#update_related_taskbars' do
    let(:key)       { Random.hex }
    let(:taskbar_1) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_2) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_3) { create(:taskbar, user: taskbar_1.user) }

    before { taskbar_1 && taskbar_2 && taskbar_3 }

    it 'updates related taskbars' do
      taskbar_1.send(:update_related_taskbars)
      perform_enqueued_jobs

      expect(taskbar_2.reload.preferences[:tasks].count).to eq(2)
      expect(taskbar_3.reload.preferences[:tasks].count).to eq(1)
    end
  end

  describe '#related_taskbars' do
    let(:key)       { Random.hex }
    let(:taskbar_1) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_2) { create(:taskbar, key: key, user: taskbar_1.user, app: 'mobile') }
    let(:taskbar_3) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_4) { create(:taskbar, user: create(:user)) }

    it 'calls related_taskbars scope' do
      taskbar = create(:taskbar)

      allow(described_class).to receive(:related_taskbars)

      taskbar.related_taskbars

      expect(described_class).to have_received(:related_taskbars).with(taskbar)
    end
  end

  describe '.related_taskbars' do
    let(:key)       { Random.hex }
    let(:taskbar_1) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_2) { create(:taskbar, key: key, user: taskbar_1.user, app: 'mobile') }
    let(:taskbar_3) { create(:taskbar, key: key, user: create(:user)) }
    let(:taskbar_4) { create(:taskbar, user: create(:user)) }

    before { taskbar_1 && taskbar_2 && taskbar_3 && taskbar_4 }

    it 'returns all taskbars with the same key except given taskbars' do
      expect(described_class.related_taskbars(taskbar_1)).to contain_exactly(taskbar_2, taskbar_3)
    end
  end

  describe '.app' do
    let(:taskbar_1) { create(:taskbar, app: 'desktop') }
    let(:taskbar_2) { create(:taskbar, app: 'mobile') }

    before { taskbar_1 && taskbar_2 }

    it 'returns given app taskbars' do
      expect(described_class.app(:desktop)).to contain_exactly(taskbar_1)
    end
  end

  describe '#saved_chanegs_to_dirty?' do
    let(:taskbar) { create(:taskbar) }

    it 'fresh taskbar has no changes to dirty' do
      expect(taskbar).not_to be_saved_change_to_dirty
    end

    it 'no changes to dirty after saving without dirty lag' do
      taskbar.active = !taskbar.active
      taskbar.save!

      expect(taskbar).not_to be_saved_change_to_dirty
    end

    it 'no changes to dirty after marking as not dirty' do
      taskbar.preferences[:dirty] = false
      taskbar.save!

      expect(taskbar).not_to be_saved_change_to_dirty
    end

    it 'dirty was changed after marking as dirty' do
      taskbar.preferences[:dirty] = true
      taskbar.save!

      expect(taskbar).to be_saved_change_to_dirty
    end

    it 'dirty was changed after marking previously dirty item as not dirty' do
      taskbar.preferences[:dirty] = true
      taskbar.save!

      taskbar.preferences[:dirty] = false
      taskbar.save!

      expect(taskbar).to be_saved_change_to_dirty
    end
  end

  describe '.to_object_ids' do
    let(:ticket)       { create(:ticket) }
    let(:ticket2)      { create(:ticket) }
    let(:organization) { create(:organization) }
    let(:user)         { create(:user) }

    let(:taskbar_ticket)       { create(:taskbar, params: { ticket_id: ticket.id }) }
    let(:taskbar_ticket2)      { create(:taskbar, params: { ticket_id: ticket2.id }) }
    let(:taskbar_organization) { create(:taskbar, params: { organization_id: organization.id }) }
    let(:taskbar_user)         { create(:taskbar, params: { user_id: user.id }) }

    before do
      taskbar_ticket && taskbar_ticket2 && taskbar_organization && taskbar_user
    end

    it 'returns object ids' do
      expect(described_class.to_object_ids).to include(
        ticket_ids:       [ticket.id, ticket2.id],
        user_ids:         [user.id],
        organization_ids: [organization.id]
      )
    end

    it 'returns object ids in scoped relation' do
      expect(described_class.where(id: [taskbar_ticket2, taskbar_user]).to_object_ids).to include(
        ticket_ids:       [ticket2.id],
        user_ids:         [user.id],
        organization_ids: []
      )
    end
  end
end

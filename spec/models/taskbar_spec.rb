# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      expect(taskbar).to validate_uniqueness_of(:key).scoped_to(%w[user_id app]).with_message(%r{})
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
      let(:ticket)        { create(:ticket) }
      let(:user)          { create(:agent, groups: [ticket.group]) }
      let(:other_user)    { create(:agent, groups: [ticket.group]) }
      let(:other_taskbar) { create(:taskbar, :with_ticket, ticket:, user: other_user) }

      before { other_taskbar }

      it 'sets tasks when creating a taskbar' do
        taskbar = create(:taskbar, :with_ticket, ticket:, user:)

        expect(taskbar.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: user.id))
      end

      it 'updates related items when creating a taskbar' do
        create(:taskbar, :with_ticket, ticket:, user:)
        perform_enqueued_jobs

        expect(other_taskbar.reload.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: user.id))
      end

      it 'sets tasks when updating a taskbar' do
        taskbar = create(:taskbar, :with_ticket, ticket:, user:)
        taskbar.update_columns preferences: {}

        taskbar.update! state: { a: :b }

        expect(taskbar.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: user.id))
      end

      it 'sets tasks when updating a taskbar with same user but different app' do
        taskbar = create(:taskbar, :with_ticket, ticket:, user: other_user, app: 'mobile')
        taskbar.update_columns preferences: {}

        taskbar.update! state: { a: :b }

        expect(taskbar.preferences[:tasks])
          .to include(include(user_id: other_user.id, apps: have_key(:desktop).and(have_key(:mobile))))
      end

      it 'updates related items when updating a taskbar' do
        taskbar = create(:taskbar, :with_ticket, ticket:, user:)

        other_taskbar.update_columns preferences: {}

        taskbar.update! state: { a: :b }

        perform_enqueued_jobs

        expect(other_taskbar.reload.preferences[:tasks]).to include(include(user_id: other_user.id), include(user_id: user.id))
      end

      it 'updates related items when destroying a taskbar' do
        taskbar = create(:taskbar, :with_ticket, ticket:, user:)
        taskbar.destroy!

        expect(other_taskbar.reload.preferences[:tasks]).to include(include(user_id: other_user.id))
      end
    end
  end

  describe '#collect_related_tasks' do
    let(:ticket)   { create(:ticket) }

    let(:user_1) { create(:agent, groups: [ticket.group]) }
    let(:user_2) { create(:agent, groups: [ticket.group]) }

    let(:taskbar_1) { create(:taskbar, :with_ticket, ticket:, user: user_1) }
    let(:taskbar_2) { create(:taskbar, :with_ticket, ticket:, user: user_2) }

    before { taskbar_2 }

    it 'returns tasks for self and related items' do
      expect(taskbar_1.send(:collect_related_tasks))
        .to eq([taskbar_2.preferences_task_info, taskbar_1.preferences_task_info])
    end

    it 'returns tasks for a new taskbar' do
      user = create(:agent, groups: [ticket.group])
      new_taskbar = build(:taskbar, :with_ticket, ticket:, user:)

      expect(new_taskbar.send(:collect_related_tasks))
        .to eq([taskbar_2.preferences_task_info, new_taskbar.preferences_task_info])
    end

    it 'do not include task of the destroyed taskbar' do
      taskbar_1

      taskbar_2.destroy!

      expect(taskbar_2.send(:collect_related_tasks))
        .to eq([taskbar_1.preferences_task_info])
    end

    # https://github.com/zammad/zammad/issues/5637
    it 'does not include user who does not have access to the ticket' do
      create(:taskbar, :with_ticket, ticket:)

      expect(taskbar_1.send(:collect_related_tasks))
        .to eq([taskbar_2.preferences_task_info, taskbar_1.preferences_task_info])
    end

    it 'does not leak other taskbars to user who does not have access to the ticket' do
      new_taskbar = build(:taskbar, :with_ticket, ticket:)

      expect(new_taskbar.send(:collect_related_tasks)).to be_empty
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
    let(:ticket)       { create(:ticket) }
    let(:other_ticket) { create(:ticket, group: ticket.group) }
    let(:user_1)       { create(:agent, groups: [ticket.group]) }
    let(:user_2)       { create(:agent, groups: [ticket.group]) }
    let(:taskbar_1)    { create(:taskbar, :with_ticket, ticket:, user: user_1) }
    let(:taskbar_2)    { create(:taskbar, :with_ticket, ticket:, user: user_2) }
    let(:taskbar_3)    { create(:taskbar, :with_ticket, ticket: other_ticket, user: user_1) }

    before { taskbar_1 && taskbar_2 && taskbar_3 }

    it 'updates related taskbars' do
      taskbar_1.send(:update_related_taskbars)
      perform_enqueued_jobs

      expect(taskbar_2.reload.preferences[:tasks].count).to eq(2)
      expect(taskbar_3.reload.preferences[:tasks].count).to eq(1)
    end

    describe 'related taskbars job enqueuing' do
      context 'when taskbar is a ticket' do
        let(:ticket)  { create(:ticket) }
        let(:taskbar) { create(:taskbar, :with_ticket, ticket:, user:) }

        context 'when user has access to the ticket' do
          let(:user) { create(:agent, groups: [ticket.group]) }

          it 'enqueues a job to update related taskbars' do
            expect { taskbar }.to have_enqueued_job(TaskbarUpdateRelatedTasksJob)
          end
        end

        context 'when user has no access to the ticket' do
          let(:user) { create(:agent) }

          it 'enqueues a job to update related taskbars' do
            expect { taskbar }.to have_enqueued_job(TaskbarUpdateRelatedTasksJob)
          end
        end
      end

      context 'when taskbar is a user' do
        let(:taskbar) { create(:taskbar, :with_user) }

        it 'does not enqueue a job to update related taskbars' do
          expect { taskbar }.not_to have_enqueued_job(TaskbarUpdateRelatedTasksJob)
        end
      end

      context 'when taskbar is a new ticket' do
        let(:taskbar) { create(:taskbar, :with_new_ticket) }

        it 'does not enqueue a job to update related taskbars' do
          expect { taskbar }.not_to have_enqueued_job(TaskbarUpdateRelatedTasksJob)
        end
      end

      context 'when taskbar is a search' do
        let(:taskbar) { create(:taskbar, :with_search) }

        it 'does not enqueue a job to update related taskbars' do
          expect { taskbar }.not_to have_enqueued_job(TaskbarUpdateRelatedTasksJob)
        end
      end
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

    let(:taskbar_ticket)       { create(:taskbar, :with_ticket, ticket:) }
    let(:taskbar_ticket2)      { create(:taskbar, :with_ticket, ticket: ticket2) }
    let(:taskbar_organization) { create(:taskbar, :with_organization, organization:) }
    let(:taskbar_user)         { create(:taskbar, :with_user, user:) }
    let(:taskbar_search)       { create(:taskbar, :with_search) }
    let(:taskbar_new_ticket)   { create(:taskbar, :with_new_ticket) }

    before do
      taskbar_ticket && taskbar_ticket2 && taskbar_organization && taskbar_user && taskbar_search && taskbar_new_ticket
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

  describe '#to_object' do
    context 'when a taskbar has a related object' do
      let(:ticket)  { create(:ticket) }
      let(:taskbar) { create(:taskbar, :with_ticket, ticket:) }

      it 'returns the related object' do
        expect(taskbar.to_object).to eq(ticket)
      end
    end

    context 'when a taskbar has no related object' do
      let(:taskbar) { create(:taskbar, :with_new_ticket) }

      it 'returns nil' do
        expect(taskbar.to_object).to be_nil
      end
    end
  end

  describe '#to_object_class' do
    context 'when a taskbar has a related object' do
      let(:taskbar) { create(:taskbar, :with_organization) }

      it 'returns the related object' do
        expect(taskbar.to_object_class).to eq(Organization)
      end
    end

    context 'when a taskbar has no related object' do
      let(:taskbar) { create(:taskbar, :with_new_ticket) }

      it 'returns nil' do
        expect(taskbar.to_object_class).to be_nil
      end
    end
  end

  describe '#to_object_id' do
    context 'when a taskbar has a related object' do
      let(:user)    { create(:user) }
      let(:taskbar) { create(:taskbar, :with_user, user:) }

      it 'returns the related object' do
        expect(taskbar.to_object_id).to eq(user.id)
      end
    end

    context 'when a taskbar has no related object' do
      let(:taskbar) { create(:taskbar, :with_new_ticket) }

      it 'returns nil' do
        expect(taskbar.to_object_id).to be_nil
      end
    end
  end

  describe '#relatable?' do
    context 'when it is a new ticket' do
      subject(:taskbar) { create(:taskbar, :with_new_ticket) }

      it { is_expected.not_to be_relatable }
    end

    context 'when it is a user' do
      subject(:taskbar) { create(:taskbar, :with_user) }

      it { is_expected.not_to be_relatable }
    end

    context 'when it is a detailed search' do
      subject(:taskbar) { create(:taskbar, :with_search) }

      it { is_expected.not_to be_relatable }
    end

    context 'when it is a ticket' do
      subject(:taskbar) { create(:taskbar, :with_ticket) }

      it { is_expected.to be_relatable }
    end
  end

  describe '#target_accessible_to_owner?' do
    context 'when taskbar is a ticket' do
      subject(:taskbar) { create(:taskbar, :with_ticket, ticket:, user:) }

      context 'when owner has agent access to the ticket' do
        let(:ticket) { create(:ticket) }
        let(:user)   { create(:agent, groups: [ticket.group]) }

        it { is_expected.to be_target_accessible_to_owner }
      end

      context 'when owner has customer access to the ticket' do
        let(:ticket) { create(:ticket, customer: user) }
        let(:user) { create(:customer) }

        it { is_expected.to be_target_accessible_to_owner }
      end

      context 'when owner has no access to the ticket' do
        let(:user) { create(:user) }
        let(:ticket) { create(:ticket) }

        it { is_expected.not_to be_target_accessible_to_owner }
      end
    end

    context 'when taskbar is a user' do
      let(:taskbar) { create(:taskbar, :with_user) }

      it { expect(taskbar.target_accessible_to_owner?).to be_nil }
    end

    context 'when taskbar is a search' do
      let(:taskbar) { create(:taskbar, :with_search) }

      it { expect(taskbar.target_accessible_to_owner?).to be_nil }
    end

    context 'when taskbar is a new ticket' do
      let(:taskbar) { create(:taskbar, :with_new_ticket) }

      it { expect(taskbar.target_accessible_to_owner?).to be_nil }
    end

    describe '#update_last_contact' do
      let(:ticket)  { create(:ticket) }
      let(:user)    { create(:agent, groups: [ticket.group]) }
      let(:taskbar) { create(:taskbar, :with_ticket, ticket:, user:) }

      before do
        freeze_time

        taskbar

        travel 1.minute
      end

      it 'sets initial contact time' do
        expect(taskbar.last_contact).to eq(1.minute.ago)
      end

      it 'updates last contact time if taskbar was updated in' do
        taskbar.state = { article: { body: 'some body' }, ticket: {} }

        expect { taskbar.save! }.to change(taskbar, :last_contact).to(Time.current)
      end

      it 'does not update last contact time if updated because of changes in a related taskbar' do
        create(:taskbar, :with_ticket, ticket:, user: create(:agent, groups: [ticket.group]))

        expect { perform_enqueued_jobs }.not_to change { taskbar.reload.last_contact }
      end

      it 'does not update last contact if taskbar was saved without any changes' do
        expect { taskbar.save! }.not_to change(taskbar, :last_contact)
      end

      it 'does not update last contact if taskbar was touched without any content changes' do
        expect { taskbar.touch }.not_to change(taskbar, :last_contact)
      end

      it 'does not update last contact if flag was the only chage' do
        taskbar.notify = true

        expect { taskbar.save! }.not_to change(taskbar, :last_contact)
      end

      it 'does not update last contact if ordering weight was the only chage' do
        taskbar.prio = 12_345

        expect { taskbar.save! }.not_to change(taskbar, :last_contact)
      end
    end
  end

  describe '#log_recent_close' do
    before do
      allow(RecentClose).to receive(:upsert_closing_time!)
    end

    context 'when taskbar has a related object' do
      let(:ticket)  { create(:ticket) }
      let(:user)    { create(:agent) }
      let(:taskbar) { create(:taskbar, :with_ticket, ticket:, user:) }

      it 'calls RecentClose.upsert_closing_time!' do
        taskbar.destroy

        expect(RecentClose).to have_received(:upsert_closing_time!).with(user, ticket)
      end
    end

    context 'when taskbar has no related object' do
      let(:user)    { create(:agent) }
      let(:taskbar) { create(:taskbar, user:) }

      it 'deos not call RecentClose.upsert_closing_time!' do
        taskbar.destroy

        expect(RecentClose).not_to have_received(:upsert_closing_time!)
      end
    end
  end
end

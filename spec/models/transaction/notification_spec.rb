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

  describe '#ooo_replacements' do
    subject(:notification_instance) { build(ticket, user) }

    let(:group)         { create(:group) }
    let(:user)          { create(:agent, :ooo, :groupable, ooo_agent: replacement_1, group: group) }
    let(:ticket)        { create(:ticket, owner: user, group: group, state_name: 'open', pending_time: Time.current) }

    context 'when replacement has access' do
      let(:replacement_1) { create(:agent, :groupable, group: group) }

      it 'is added to list' do
        replacements = Set.new

        ooo(notification_instance, user, replacements: replacements)

        expect(replacements).to include replacement_1
      end

      context 'when replacement has replacement' do
        let(:replacement_1) { create(:agent, :ooo, :groupable, ooo_agent: replacement_2, group: group) }
        let(:replacement_2) { create(:agent, :groupable, group: group) }

        it 'replacement\'s replacement added to list' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).to include replacement_2
        end

        it 'intermediary replacement is not in list' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).not_to include replacement_1
        end
      end
    end

    context 'when replacement does not have access' do
      let(:replacement_1) { create(:agent) }

      it 'is not added to list' do
        replacements = Set.new

        ooo(notification_instance, user, replacements: replacements)

        expect(replacements).not_to include replacement_1
      end

      context 'when replacement has replacement with access' do
        let(:replacement_1) { create(:agent, :ooo, ooo_agent: replacement_2) }
        let(:replacement_2) { create(:agent, :groupable, group: group) }

        it 'his replacement may be added' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).to include replacement_2
        end
      end
    end
  end

  def run(ticket, user, type)
    build(ticket, user, type).perform
  end

  def build(ticket, user, type = 'reminder_reached')
    described_class.new(
      object:           ticket.class.name,
      type:             type,
      object_id:        ticket.id,
      interface_handle: 'scheduler',
      changes:          nil,
      created_at:       Time.current,
      user_id:          user.id
    )
  end

  def ooo(instance, user, replacements: Set.new, reasons: [])
    instance.send(:ooo_replacements, user: user, replacements: replacements, ticket: ticket, reasons: reasons)
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/concerns/checks_human_changes_examples'

RSpec.describe Transaction::Notification, type: :model do
  describe 'pending ticket reminder repeats after midnight at selected time zone', time_zone: 'UTC' do
    let(:group)  { create(:group) }
    let(:user)   { create(:agent) }
    let(:ticket) { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }

    before do
      travel_to DateTime.parse('2024-11-15T12:00:00Z')

      user.groups << group
      ticket

      Setting.set('timezone_default', 'America/Santiago')
      run(ticket, user, 'reminder_reached')
      OnlineNotification.destroy_all
    end

    it 'notification not sent at UTC midnight' do
      travel_to DateTime.parse('2024-11-16T00:01:00Z')

      expect { run(ticket, user, 'reminder_reached') }.not_to change(OnlineNotification, :count)
    end

    it 'notification sent at selected time zone midnight' do
      travel_to DateTime.parse('2024-11-16T03:01:00Z')

      expect { run(ticket, user, 'reminder_reached') }.to change(OnlineNotification, :count).by(1)
    end
  end

  # https://github.com/zammad/zammad/issues/4066
  describe 'notification sending reason may be fully translated' do
    let(:group) { create(:group) }
    let(:user)      { create(:agent, groups: [group]) }
    let(:ticket)    { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }
    let(:reason_en) { 'You are receiving this because you are the owner of this ticket.' }
    let(:reason_de) do
      Translation.translate('de-de', reason_en).tap do |translated|
        expect(translated).not_to eq(reason_en) # rubocop:disable RSpec/ExpectInLet
      end
    end

    before do
      allow(NotificationFactory::Mailer).to receive(:deliver)
    end

    it 'notification includes English footer' do
      run(ticket, user, 'reminder_reached')

      expect(NotificationFactory::Mailer)
        .to have_received(:deliver)
        .with hash_including body: %r{#{reason_en}}
    end

    context 'when locale set to Deutsch' do
      before do
        user.preferences[:locale] = 'de-de'
        user.save
      end

      it 'notification includes German footer' do
        run(ticket, user, 'reminder_reached')

        expect(NotificationFactory::Mailer)
          .to have_received(:deliver)
          .with hash_including body: %r{#{reason_de}}
      end
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

  describe 'SMTP errors' do
    let(:group)    { create(:group) }
    let(:user)     { create(:agent, groups: [group]) }
    let(:ticket)   { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }
    let(:response) { Net::SMTP::Response.new(response_status_code, 'mocked SMTP response') }
    let(:error)    { Net::SMTPFatalError.new(response) }

    before do
      allow_any_instance_of(Net::SMTP).to receive(:start).and_raise(error)

      Service::System::SetEmailNotificationConfiguration
        .new(
          adapter:           'smtp',
          new_configuration: {}
        ).execute
    end

    context 'when there is a problem with the sending SMTP server' do
      let(:response_status_code) { 535 }

      it 'raises an eroror' do
        expect { run(ticket, user, 'reminder_reached') }
          .to raise_error(Channel::DeliveryError)
      end
    end

    context 'when there is a problem with the receiving SMTP server' do
      let(:response_status_code) { 550 }

      it 'logs the information about failed email delivery' do
        allow(Rails.logger).to receive(:info)
        run(ticket, user, 'reminder_reached')
        expect(Rails.logger).to have_received(:info)
      end
    end
  end

  describe 'daily locks behaviour' do
    let(:group)      { create(:group) }
    let(:user)       { create(:agent, groups: [group]) }
    let(:other_user) { create(:agent, groups: [group]) }
    let(:ticket)     { create(:ticket, group:, state_name: 'open', pending_time: Time.current) }
    let(:instance)   { build(ticket, user, 'reminder_reached') }

    def user_gets_reminders(user)
      user.preferences[:notification_config][:matrix][:reminder_reached][:criteria] = {
        'owned_by_me' => true, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => true
      }
      user.save!
    end

    before do
      travel_to Time.current.noon

      [user, other_user].each { user_gets_reminders(it) }

      allow(instance).to receive(:send_to_single_recipient_online)
    end

    context 'with existing locks' do
      before do
        run(ticket, user, 'reminder_reached')
      end

      it 'notification not resent on same day' do
        instance.perform

        expect(instance).not_to have_received(:send_to_single_recipient_online)
      end

      it 'notification is resent on same day if ticket pending time changes' do
        ticket.update!(pending_time: 1.hour.from_now)

        instance.perform

        expect(instance).to have_received(:send_to_single_recipient_online).twice
      end

      context 'when next day' do
        before { travel 1.day }

        it 'notification is resent on next day' do
          instance.perform

          expect(instance).to have_received(:send_to_single_recipient_online).twice
        end

        it 'notification lock is gone next day' do
          expect { run(ticket, other_user, 'reminder_reached') }.to change(Ticket::DailyEventLock, :count).by(2)
        end
      end

      context 'with an additional user' do
        let(:new_user) { create(:agent, groups: [group]) }

        before do
          user_gets_reminders(new_user)
          Rails.cache.clear # clears cache because notification preferences are cached
        end

        it 'notification is sent to new user on same day' do
          instance.perform

          expect(instance).to have_received(:send_to_single_recipient_online).once
        end
      end
    end

    it 'one of notification locks are present when one user fails', aggregate_failures: true do
      call_count = 0
      allow(instance).to receive(:send_to_single_recipient_online) do
        raise StandardError if call_count.positive?

        call_count += 1
      end

      expect do
        expect { instance.perform }.to raise_error(StandardError)
      end.to change(Ticket::DailyEventLock, :count).by(1)
    end
  end

  it_behaves_like 'ChecksHumanChanges'

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

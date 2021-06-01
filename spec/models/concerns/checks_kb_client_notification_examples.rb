# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ChecksKbClientNotification' do
  context 'sends client notifications', performs_jobs: true do
    before { subject }

    it 'on creation' do
      expect(ChecksKbClientNotificationJob).to have_been_enqueued.at_least(:once) # some object have associations that triggers touch job after creation
    end

    context 'after initial notifications are cleared' do
      before { clear_jobs }

      it 'on update' do
        subject.update(updated_at: Time.zone.now)
        expect(ChecksKbClientNotificationJob).to have_been_enqueued.at_least(:once) # some object have associations that triggers touch job after creation
      end

      it 'on touch' do
        subject.touch
        expect(ChecksKbClientNotificationJob).to have_been_enqueued.at_least(:once) # some object have associations that triggers touch job after creation
      end

      it 'on destroy' do
        subject.destroy
        expect(ChecksKbClientNotificationJob).to have_been_enqueued.at_least(:once) # some object have associations that triggers touch job after creation
      end

      it 'notifications be disabled' do
        ChecksKbClientNotification.disable_in_all_classes!
        subject.update(updated_at: Time.zone.now)
        expect(ChecksKbClientNotificationJob).not_to have_been_enqueued.at_least(:once) # some object have associations that triggers touch job after creation
      end

      it 'notifications be re-enabled' do
        ChecksKbClientNotification.disable_in_all_classes!
        ChecksKbClientNotification.enable_in_all_classes!
        subject.update(updated_at: Time.zone.now)
        expect(ChecksKbClientNotificationJob).to have_been_enqueued.at_least(:once) # some object have associations that triggers touch job after creation
      end
    end
  end
end

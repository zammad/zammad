RSpec.shared_examples 'TriggesWebhooks' do
  subject { create(described_class.name.underscore) }

  context 'when a webhook are created' do
    let(:webhook) { create(:webhook) }

    context 'on creation', performs_jobs: true do
      it 'schedules the webhooks notification job' do
        expect { subject }.to have_enqueued_job(Webhooks::NotificationJob).with(resource_type: described_class.name.underscore, resource_id: anything, webhook_id: webhook.id, event: 'created')
      end
    end

    context 'on updation', performs_jobs: true do
      it 'schedules the webhooks notification job' do
        subject

        expect { subject.update(title: 'My new title') }.to have_enqueued_job(Webhooks::NotificationJob).with(resource_type: described_class.name.underscore, resource_id: subject.id, webhook_id: webhook.id, event: 'updated')
      end
    end

    context 'on destroyng', performs_jobs: true do
      it 'schedules the webhooks notification job' do
        subject

        expect { subject.destroy }.to have_enqueued_job(Webhooks::NotificationJob).with(resource_type: described_class.name.underscore, resource_id: subject.id, webhook_id: webhook.id, event: 'destroyed')
      end
    end
  end

  context 'when no webhook are created' do
    context 'on creation', performs_jobs: true do
      it 'does not schedule webhooks notification job' do
        expect { subject }.not_to have_enqueued_job(Webhooks::NotificationJob)
      end
    end

    context 'on updation', performs_jobs: true do
      it 'does not schedule webhooks notification job' do
        subject

        expect { subject.update(title: 'My new title') }.not_to have_enqueued_job(Webhooks::NotificationJob)
      end
    end

    context 'on destroyng', performs_jobs: true do
      it 'does not schedule webhooks notification job' do
        subject

        expect { subject.destroy }.not_to have_enqueued_job(Webhooks::NotificationJob)
      end
    end
  end
end

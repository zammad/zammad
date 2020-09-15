RSpec.shared_examples 'TriggesWebhooks' do
  subject { create(described_class.name.underscore) }

  context "when a webhook are created" do
    describe 'call the webhook URLs' do
      context 'on creation', performs_jobs: true do
        it 'schedules the webhooks notification job' do
          expect { subject }.to have_enqueued_job(Webhooks::NotificationJob)
        end
      end

      context 'on updation', performs_jobs: true do
        it 'schedules the webhooks notification job' do
          subject

          expect { subject.update(subject: "My new subject") }.to have_enqueued_job(Webhooks::NotificationJob)
        end
      end

      context 'on destroyng', performs_jobs: true do
        it 'schedules the webhooks notification job' do
          subject

          expect { subject.destroy }.to have_enqueued_job(Webhooks::NotificationJob)
        end
      end
    end
  end

  context "when no webhook are created" do
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasTicketCreateScreenImpact' do |create_screen_factory:|

  describe '#push_ticket_create_screen', performs_jobs: true do
    subject { create(create_screen_factory) }

    context 'creating a record' do
      it 'enqueues a TicketCreateScreenJob job' do
        expect { subject }.to have_enqueued_job(TicketCreateScreenJob)
      end
    end

    context 'record exists' do

      before do
        subject
        clear_jobs
      end

      context 'attribute updated' do

        context 'name' do
          it 'enqueues a TicketCreateScreenJob job' do
            expect do
              subject.name = 'New name'
              subject.save!
            end.to have_enqueued_job(TicketCreateScreenJob)
          end
        end

        context 'updated_at' do
          it 'enqueues a TicketCreateScreenJob job' do
            expect { subject.touch }.to have_enqueued_job(TicketCreateScreenJob)
          end
        end
      end

      context 'record is deleted' do
        it 'enqueues a TicketCreateScreenJob job' do
          expect { subject.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end
    end
  end
end

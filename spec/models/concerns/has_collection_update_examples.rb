# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasCollectionUpdate' do |collection_factory:|

  describe '#push_collection_to_clients', performs_jobs: true do
    subject { create(collection_factory) }

    context 'creating a record' do

      it 'enqueues a CollectionUpdateJob job' do
        expect { subject }.to have_enqueued_job(CollectionUpdateJob).with(described_class.name)
      end
    end

    context 'record exists' do

      before do
        subject
        clear_jobs
      end

      context 'attribute updated' do

        context 'name' do
          it 'enqueues a CollectionUpdateJob job' do
            expect do

              if subject.respond_to?(:name)
                subject.name = 'New name'
              else
                # EmailAdress has no `name` attribute
                subject.realname = 'New name'
              end
              subject.save!
            end.to have_enqueued_job(CollectionUpdateJob).with(described_class.name)
          end
        end

        context 'updated_at' do
          it 'enqueues a CollectionUpdateJob job' do
            expect { subject.touch }.to have_enqueued_job(CollectionUpdateJob).with(described_class.name)
          end
        end
      end

      context 'record is deleted' do

        it 'enqueues a CollectionUpdateJob job' do
          expect { subject.destroy! }.to have_enqueued_job(CollectionUpdateJob).with(described_class.name)
        end
      end
    end
  end
end

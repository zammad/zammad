# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HasCollectionUpdate, type: :job do

  context 'with groups' do

    let!(:group) { create(:group) }

    it 'create should enqueue no job' do
      collection_jobs = enqueued_jobs.select do |job|
        job[:job] == CollectionUpdateJob && job[:args][0] == 'Group'
      end

      expect(collection_jobs.count).to be(1)
    end

    context 'updating attribute' do
      before do
        clear_jobs
      end

      context 'name' do
        it 'enqueues a job' do
          expect { group.update!(name: 'new name') }.to have_enqueued_job(CollectionUpdateJob).with('Group')
        end
      end

      context 'updated_at' do
        it 'enqueues a job' do
          expect { group.touch }.to have_enqueued_job(CollectionUpdateJob).with('Group')
        end
      end
    end

    it 'delete should enqueue a job' do
      clear_jobs
      expect { group.destroy! }.to have_enqueued_job(CollectionUpdateJob).with('Group')
    end
  end
end

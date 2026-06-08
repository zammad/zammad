# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveJobLock, type: :model do
  let(:job_class) do
    Class.new(ApplicationJob) do
      include HasActiveJobLock

      def lock_key
        "test_lock_key_#{Random.hex}"
      end
    end
  end

  describe '#related_job' do
    let(:job)             { Delayed::Job.last }
    let(:active_job_lock) { described_class.last }

    before do
      job_class.perform_later
      job_class.perform_later
      job && active_job_lock
      job_class.perform_later
    end

    it 'returns correct job' do
      expect(active_job_lock.related_job).to eq job
    end
  end
end

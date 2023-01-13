# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ZammadActiveJobHelper
  delegate :enqueued_jobs, :performed_jobs, to: :queue_adapter

  def queue_adapter
    ::ActiveJob::Base.queue_adapter
  end

  def clear_jobs
    enqueued_jobs.clear
    performed_jobs.clear
    ActiveJobLock.destroy_all
  end
end

module ZammadActiveJobSystemHelper
  include ActiveJob::TestHelper

  alias original_perform_enqueued_jobs perform_enqueued_jobs

  def perform_enqueued_jobs(**kwargs, &)
    if kwargs[:commit_transaction]
      TransactionDispatcher.commit
      kwargs.delete :commit_transaction
    end

    ActiveJobLock.destroy_all
    original_perform_enqueued_jobs(**kwargs, &)
  end
end

RSpec.configure do |config|

  activate_for = {
    type:          :job, # actual Job examples
    performs_jobs: true, # examples performing Jobs
  }

  config.include ZammadActiveJobSystemHelper, performs_jobs: true, type: :system

  activate_for.each do |key, value|
    config.include ZammadActiveJobHelper, key => value
    config.include RSpec::Rails::JobExampleGroup, key => value

    config.around(:each, key => value) do |example|

      default_queue_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test

      clear_jobs

      example.run

    ensure
      ActiveJob::Base.queue_adapter = default_queue_adapter
    end
  end

  # Workaround needed for behavior change introduced in Rails >= 5.2
  # see: https://github.com/rails/rails/issues/37270
  config.before do
    (ActiveJob::Base.descendants << ActiveJob::Base).each(&:disable_test_adapter)
  end
end

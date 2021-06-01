# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

RSpec.configure do |config|

  activate_for = {
    type:          :job, # actual Job examples
    performs_jobs: true, # examples performing Jobs
  }

  activate_for.each do |key, value|
    config.include ZammadActiveJobHelper, key => value
    config.include RSpec::Rails::JobExampleGroup, key => value

    config.around(:each, key => value) do |example|

      default_queue_adapter           = ::ActiveJob::Base.queue_adapter
      ::ActiveJob::Base.queue_adapter = :test

      clear_jobs

      example.run

    ensure
      ::ActiveJob::Base.queue_adapter = default_queue_adapter
    end
  end
end

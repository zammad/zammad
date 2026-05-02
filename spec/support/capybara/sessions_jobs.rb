# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.before(type: :system) do |example|
    sessions_jobs_required = example.metadata.fetch(:sessions_jobs, false)

    next if !sessions_jobs_required

    allow_any_instance_of(Sessions::Backend::Base).to receive(:to_run?).and_return(true)
  end

  config.around(:each, type: :system) do |example|
    sessions_jobs_required = example.metadata.fetch(:sessions_jobs, false)

    if sessions_jobs_required
      sessions_jobs_thread = Thread.new do
        BackgroundServices::Service::ProcessSessionsJobs
          .new(manager: nil)
          .launch
      end
    end

    example.run

    next if !sessions_jobs_required

    sessions_jobs_thread.exit
    sessions_jobs_thread.join
  end
end

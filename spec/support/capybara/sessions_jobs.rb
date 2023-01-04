# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
        # Try to work around a problem with ActiveRecord::StatementInvalid: Mysql2::Error:
        #   This connection is in use by: #<Thread:0x000000000e940e18 /builds/zammad/zammad/lib/sessions.rb:533 dead>
        ActiveRecord::Base.connection_pool.release_connection

        Sessions.jobs
      end
    end

    example.run

    next if !sessions_jobs_required

    sessions_jobs_thread.exit
    sessions_jobs_thread.join
  end
end

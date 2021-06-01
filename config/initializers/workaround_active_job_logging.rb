# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This is a workaround because `ActiveSupport::Subscriber` supports only `attach_to` but not `detach_from` in Rails 5.2.
# `detach_from` was added with Rails 6.0: https://github.com/rails/rails/commit/ca19b7f5d86aa590077766cbe8006f952b6d4296
# Once Rails 6.0 is used `ActiveJob::Logging::LogSubscriber.detach_from :active_job` needs to be added to `app/jobs/application_job.rb` instead.
ActiveSupport.on_load(:active_job) do

  # gather all `ActiveJob::Logging::LogSubscriber` event subscribers
  subscribers = ActiveSupport::Notifications.notifier.instance_variable_get(:@subscribers).select do |subscriber|
    subscriber.instance_variable_get(:@delegate).instance_of?(ActiveJob::Logging::LogSubscriber)
  end

  # remove gathered event subscribers in a dedicated step to not work on iterating array
  subscribers.each do |subscriber|
    ActiveSupport::Notifications.notifier.unsubscribe(subscriber)
  end

  # remove whole `ActiveJob::Logging::LogSubscriber` subscriber reference
  ActiveSupport::Subscriber.subscribers.delete_if { |subscriber| subscriber.instance_of?(ActiveJob::Logging::LogSubscriber) }
end

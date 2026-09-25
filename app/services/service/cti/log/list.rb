# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Like Cti::Log.log_records, but without its view_limit: the GraphQL connection pages over it.
class Service::Cti::Log::List < Service::Base
  requires_current_user!

  def execute
    scope = ::Cti::Log.reorder(created_at: :desc)

    queues = Service::Cti::Log::QueueFilter.with_current_user(current_user).execute
    return scope if queues.nil?

    scope.where(queue: queues)
  end
end

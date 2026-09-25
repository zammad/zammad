# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The queues cti_config[:notify_map] limits the current user's caller log to, as
#   Cti::Log.log_records applies it. nil is no limit: without a notify map every agent sees every call.
class Service::Cti::Log::QueueFilter < Service::Base
  requires_current_user!

  def execute
    cti_config = Setting.get('cti_config')
    return if cti_config[:notify_map].blank?

    ::Cti::Log.queues_of_user(current_user, cti_config)
  end
end

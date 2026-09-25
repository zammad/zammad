# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Only an entry of the current user's own caller log may be marked: the scope
#   Service::Cti::Log::List reads from decides it, so the read and the write path agree.
class Service::Cti::Log::DoneUpdate < Service::Base
  requires_current_user!

  attr_reader :log, :done

  def initialize(log:, done:)
    @log  = log
    @done = done
  end

  def execute
    raise Exceptions::Forbidden, __('The call is not in your caller log.') if !visible?

    log.update!(done:)
    log
  end

  private

  def visible?
    Service::Cti::Log::List.with_current_user(current_user).execute.exists?(log.id)
  end
end

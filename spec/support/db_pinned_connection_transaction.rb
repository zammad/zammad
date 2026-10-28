# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Spec and server threads share the pinned connection, and ActiveRecord joins an open transaction
#   without its lock: a spec write could land in a server request's transaction and lose its after_commit.
module ZammadPinnedConnectionTransaction
  def transaction(...)
    lock.synchronize { super }
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ZammadPinnedConnectionTransaction)

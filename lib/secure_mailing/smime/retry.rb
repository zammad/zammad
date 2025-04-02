# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::Retry < SecureMailing::Backend::HandlerRetry
  def type
    'S/MIME'
  end
end

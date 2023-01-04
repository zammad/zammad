# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::SecureMailing

  def self.run(_channel, mail, _transaction_params)
    ::SecureMailing.incoming(mail)
  end
end

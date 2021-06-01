# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::SecureMailing

  def self.run(_channel, mail, _transaction_params)
    ::SecureMailing.incoming(mail)
  end
end

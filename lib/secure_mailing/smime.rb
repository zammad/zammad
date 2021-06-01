# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SecureMailing::SMIME < SecureMailing::Backend

  def self.active?
    Setting.get('smime_integration')
  end
end

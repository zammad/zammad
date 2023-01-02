# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Ldap::Connection < Sequencer::Unit::Common::Provider::Fallback

  uses :ldap_config
  provides :ldap_connection

  private

  def ldap_connection
    ::Ldap.new(ldap_config)
  end
end

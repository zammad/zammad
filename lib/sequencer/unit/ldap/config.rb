# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Ldap::Config < Sequencer::Unit::Common::Provider::Fallback

  uses :resource
  provides :ldap_config

  private

  def ldap_config
    resource
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Mapping < Sequencer::Unit::Import::Common::Mapping::FlatKeys
  uses :ldap_config

  private

  def mapping
    ldap_config[:user_attributes]
  end
end

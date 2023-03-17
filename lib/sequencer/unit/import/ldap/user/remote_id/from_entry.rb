# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::RemoteId::FromEntry < Sequencer::Unit::Import::Common::Model::Attributes::RemoteId

  uses :ldap_config

  private

  def attribute
    ldap_config[:user_uid].to_sym
  end
end

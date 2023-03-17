# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::Users::UserRoles < Sequencer::Unit::Base
  uses :ldap_config, :ldap_connection
  provides :dn_roles

  def process

    state.provide(:dn_roles) do

      group_config = {
        filter: ldap_config[:group_filter]
      }

      ldap_group = ::Ldap::Group.new(group_config, ldap: ldap_connection)

      ldap_group.user_roles(ldap_config[:group_role_map])
    end
  end
end

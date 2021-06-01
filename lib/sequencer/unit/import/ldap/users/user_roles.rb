# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ldap'
require_dependency 'ldap/group'

class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class UserRoles < Sequencer::Unit::Base
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
        end
      end
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Attributes
            module RoleIds
              class Dn < Sequencer::Unit::Base
                include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

                skip_any_action

                uses :resource, :remote_id, :dn_roles

                def process
                  dn = resource[:dn]
                  raise "Missing 'dn' attribute for remote id '#{remote_id}'" if dn.blank?

                  # use signup/Zammad default roles
                  # if no mapping was provided
                  return if dn_roles.blank?

                  # check if roles are mapped for the found dn
                  role_ids = dn_roles[ dn.downcase ]

                  # use signup/Zammad default roles
                  # if no mapping entry was found
                  return if role_ids.blank?

                  # LDAP is the leading source if
                  # a mapping entry is present
                  provide_mapped do
                    {
                      role_ids: role_ids
                    }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Attributes
            module RoleIds
              class Unassigned < Sequencer::Unit::Base
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::InstanceAction

                skip_any_instance_action

                uses :resource, :dn_roles, :ldap_config, :mapped
                provides :instance_action

                def process
                  # use signup/Zammad default roles
                  # if no mapping was provided
                  return if dn_roles.blank?

                  # return if a mapping entry was found
                  return if mapped[:role_ids].present?

                  # use signup/Zammad default roles
                  # if unassigned users should not get skipped
                  return if ldap_config[:unassigned_users] != 'skip_sync'

                  instance = state.optional(:instance)

                  if instance.present?
                    # deactivate instance if role assignment is lost
                    instance.update!(active: false)
                    state.provide(:instance_action, :deactivated)
                  else
                    # skip instance creation if no existing
                    # instance was found yet
                    state.provide(:instance_action, :skipped)
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

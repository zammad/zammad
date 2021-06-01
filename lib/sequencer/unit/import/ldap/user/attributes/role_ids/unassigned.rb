# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Attributes
            module RoleIds
              class Unassigned < Sequencer::Unit::Base
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

                skip_any_action

                uses :dn_roles, :ldap_config, :mapped, :instance
                provides :action

                def process
                  # use signup/Zammad default roles
                  # if no mapping was provided
                  return if dn_roles.blank?

                  # return if a mapping entry was found
                  return if mapped[:role_ids].present?

                  # use signup/Zammad default roles
                  # if unassigned users should not get skipped
                  return if ldap_config[:unassigned_users] != 'skip_sync'

                  if instance&.active
                    # deactivate instance if role assignment is lost
                    instance.update!(active: false)
                    state.provide(:action, :deactivated)
                  else
                    # skip instance creation if no existing instance was found yet
                    logger.info { "Skipping. No Role assignment found for login '#{mapped[:login]}'" }
                    state.provide(:action, :skipped)
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

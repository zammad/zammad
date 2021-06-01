# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class Roles < Sequencer::Unit::Common::Provider::Named

            uses :resource, :initiator

            private

            def roles
              return admin if initiator

              map_roles
            end

            def map_roles
              return send(zendesk_role) if respond_to?(zendesk_role, true)

              logger.error "Unknown mapping for role '#{resource.role.name}' (method: #{zendesk_role})"
              end_user
            end

            def zendesk_role
              @zendesk_role ||= resource.role.name.tr('-', '_').to_sym
            end

            def end_user
              [role_customer]
            end

            def agent
              return [role_agent] if resource.restricted_agent

              admin
            end

            def admin
              [role_admin, role_agent]
            end

            def role_admin
              @role_admin ||= lookup('Admin')
            end

            def role_agent
              @role_agent ||= lookup('Agent')
            end

            def role_customer
              @role_customer ||= lookup('Customer')
            end

            def lookup(role_name)
              ::Role.lookup(name: role_name)
            end
          end
        end
      end
    end
  end
end

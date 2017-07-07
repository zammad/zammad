# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require 'import/zendesk/user'

module Import
  module Zendesk
    class User
      module Role
        extend Import::Helper

        # rubocop:disable Style/ModuleFunction
        extend self

        def for(user)
          map(user, group_method( user.role.name ))
        end

        def map(user, role)
          send(role.to_sym, user)
        rescue NoMethodError => e
          log "Unknown mapping for role '#{user.role.name}' and user with id '#{user.id}'"
          []
        end

        private

        def end_user(_user)
          [role_customer]
        end

        def agent(user)
          return [ role_agent ] if user.restricted_agent
          admin(user)
        end

        def admin(_user)
          [role_admin, role_agent]
        end

        def group_method(role)
          role.tr('-', '_')
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

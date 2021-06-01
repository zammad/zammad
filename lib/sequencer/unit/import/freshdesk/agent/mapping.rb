# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Agent
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
            extend ::Sequencer::Unit::Import::Freshdesk::Requester

            uses :resource, :id_map

            def process
              contact = resource['contact']

              provide_mapped do
                {
                  login:      contact['email'],
                  firstname:  contact['name'],
                  email:      contact['email'],
                  phone:      contact['phone'],
                  active:     contact['active'],
                  group_ids:  group_ids,
                  password:   password,
                  last_login: contact['last_login_at'],
                  role_ids:   ::Role.where(name: role_names).pluck(:id),
                }
              end
            end

            def self.admin_id
              @admin_id ||= begin
                token_user = self.token_user
                token_user.try(:[], 'id')
              end
            end

            def self.token_user
              response = request(
                api_path: 'agents/me',
              )

              JSON.parse(response.body)
            rescue => e
              logger.error e
              nil
            end

            private

            def group_ids
              Array(resource['group_ids']).map do |group_id|
                id_map['Group'][group_id]
              end
            end

            def role_names
              return %w[Agent Admin] if token_user?

              'Agent'
            end

            def password
              return Setting.get('import_freshdesk_endpoint_key') if token_user?

              nil
            end

            def token_user?
              self.class.admin_id == resource['id']
            end
          end
        end
      end
    end
  end
end

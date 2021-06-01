# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource, :login, :password, :roles, :groups, :organization_id, :image_source

            def process
              provide_mapped do
                {
                  login:           login,
                  firstname:       resource.name,
                  email:           resource.email,
                  phone:           resource.phone,
                  password:        password,
                  active:          !resource.suspended,
                  groups:          groups,
                  roles:           roles,
                  note:            resource.notes,
                  verified:        resource.verified,
                  organization_id: organization_id,
                  last_login:      resource.last_login_at,
                  image_source:    image_source,
                }
              end
            end
          end
        end
      end
    end
  end
end

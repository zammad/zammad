# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Contact
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource, :id_map

            def process
              provide_mapped do
                {
                  firstname:       resource['name'],
                  active:          resource['active'],
                  organization_id: organization_id,
                  email:           resource['email'],
                  mobile:          resource['mobile'],
                  phone:           resource['phone'],
                  image_source:    resource['avatar'],
                  group_ids:       [],
                  role_ids:        ::Role.where(name: 'Customer').pluck(:id),
                }
              end
            end

            private

            def organization_id
              id_map['Organization'][resource['company_id']]
            end
          end
        end
      end
    end
  end
end

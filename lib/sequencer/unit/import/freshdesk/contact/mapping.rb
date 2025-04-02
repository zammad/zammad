# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Contact::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :id_map

  def process
    provide_mapped do
      {
        firstname:       resource['name'],
        lastname:        '', # makes sure name guessing is triggered for updating existing users.
        active:          !resource['deleted'],
        organization_id: organization_id,
        email:           resource['email'],
        mobile:          resource['mobile'],
        phone:           resource['phone'],
        group_ids:       [],
        role_ids:        ::Role.where(name: 'Customer').pluck(:id),
      }
    end
  end

  private

  def organization_id
    id_map.dig('Organization', resource['company_id'])
  end
end

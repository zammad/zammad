# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :customer_id, :owner_id, :group_id, :organization_id, :priority_id, :state_id,
       :created_by_id, :updated_by_id, :type

  def process
    provide_mapped do
      {
        id:              resource['id'],
        number:          resource['id'],
        title:           resource['subject'],
        owner_id:        owner_id,
        group_id:        group_id,
        customer_id:     customer_id,
        organization_id: organization_id,
        priority_id:     priority_id,
        state_id:        state_id,
        type:            type,
        updated_by_id:   updated_by_id,
        created_by_id:   created_by_id,
      }
    end
  end
end

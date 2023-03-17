# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::TimeEntry::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :id_map

  def process
    provide_mapped do
      {
        time_unit:     time_unit,
        ticket_id:     ticket_id,
        created_by_id: agent_id,
        created_at:    resource['created_at'],
        updated_at:    resource['updated_at'],
      }
    end
  end

  private

  def time_unit
    hours, minutes = resource['time_spent'].match(%r{(\d{2}):(\d{2})}).captures
    (hours.to_i * 60) + minutes.to_i
  end

  def ticket_id
    id_map['Ticket'][resource['ticket_id']]
  end

  def agent_id
    id_map['User'][resource['agent_id']]
  end
end

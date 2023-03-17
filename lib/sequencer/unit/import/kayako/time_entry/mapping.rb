# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::TimeEntry::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :id_map, :created_by_id
  provides :action

  def process
    provide_mapped do
      {
        time_unit:     time_unit,
        ticket_id:     ticket_id,
        created_by_id: created_by_id,
      }
    end
  end

  private

  def time_unit
    resource['time_spent'].to_i / 60
  end

  def ticket_id
    id_map['Ticket'][resource['case']['id']]
  end
end

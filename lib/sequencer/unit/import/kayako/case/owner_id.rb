# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::OwnerId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def owner_id
    id_map['User'].fetch(resource['assigned_agent']&.fetch('id'), 1)
  end
end

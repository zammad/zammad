# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Common::CreatedById < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def created_by_id
    id_map['User'].fetch(resource['creator']&.fetch('id'), 1)
  end
end

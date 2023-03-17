# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::GroupId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def group_id
    id_map['Group'].fetch(resource['assigned_team']&.fetch('id'), 1)
  end
end

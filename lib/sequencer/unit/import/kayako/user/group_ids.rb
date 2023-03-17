# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::GroupIds < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def group_ids
    Array(resource['teams']).map do |team|
      id_map['Group'][team['id']]
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::Tags < Sequencer::Unit::Common::Model::Tags

  uses :resource

  private

  def tags
    resource['tags']&.pluck('name')
  end
end

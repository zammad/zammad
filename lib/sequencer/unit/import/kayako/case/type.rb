# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::Type < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def type
    type = resource['type']&.fetch('type')
    type&.capitalize
  end
end

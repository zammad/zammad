# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::Tags < Sequencer::Unit::Common::Model::Tags

  uses :resource

  private

  def tags
    resource['tags']&.map { |tag| tag['name'] }
  end
end

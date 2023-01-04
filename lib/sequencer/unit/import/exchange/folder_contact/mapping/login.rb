# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContact::Mapping::Login < Sequencer::Unit::Import::Common::Mapping::FlatKeys
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :remote_id

  def process
    provide_mapped do
      {
        login: remote_id
      }
    end
  end
end

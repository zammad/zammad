# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Mapping::Timestamps < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource

  def process
    provide_mapped do
      {
        created_at: resource['created_at'],
        updated_at: resource['updated_at'],
      }
    end
  end
end

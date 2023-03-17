# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Company::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource

  def process
    provide_mapped do
      {
        name:   resource['name'],
        note:   resource['description'],
        domain: resource['domains']&.first,
      }
    end
  end
end

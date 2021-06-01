# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Request < Sequencer::Unit::Common::Provider::Attribute
          class Ticket < Sequencer::Unit::Import::Freshdesk::Request::Generic

            def params
              super.merge(
                updated_since: '1970-01-01',
                order_type:    :asc,
              )
            end
          end
        end
      end
    end
  end
end

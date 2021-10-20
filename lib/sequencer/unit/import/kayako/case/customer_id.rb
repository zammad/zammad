# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          class CustomerId < Sequencer::Unit::Common::Provider::Named

            uses :resource, :id_map

            private

            def customer_id
              id_map['User'].fetch(resource['requester']&.fetch('id'), 1)
            end
          end
        end
      end
    end
  end
end

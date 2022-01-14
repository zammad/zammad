# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          class UpdatedById < Sequencer::Unit::Common::Provider::Named

            uses :resource, :id_map, :created_by_id

            private

            def updated_by_id
              id_map['User'].fetch(resource['last_updated_by']&.fetch('id'), created_by_id)
            end
          end
        end
      end
    end
  end
end

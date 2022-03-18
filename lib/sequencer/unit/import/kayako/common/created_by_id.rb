# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Common
          class CreatedById < Sequencer::Unit::Common::Provider::Named

            uses :resource, :id_map

            private

            def created_by_id
              id_map['User'].fetch(resource['creator']&.fetch('id'), 1)
            end
          end
        end
      end
    end
  end
end

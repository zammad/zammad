# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          class GroupId < Sequencer::Unit::Common::Provider::Named

            uses :resource, :id_map

            private

            def group_id
              id_map['Group'].fetch(resource['assigned_team']&.fetch('id'), 1)
            end
          end
        end
      end
    end
  end
end

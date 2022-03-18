# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          class Type < Sequencer::Unit::Common::Provider::Named

            uses :resource

            private

            def type
              type = resource['type']&.fetch('type')
              type&.capitalize
            end
          end
        end
      end
    end
  end
end

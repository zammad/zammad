# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Mapping
          class Timestamps < Sequencer::Unit::Base
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
        end
      end
    end
  end
end

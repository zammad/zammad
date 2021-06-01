# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module AttributeMapper
          class AttributeExamples < Sequencer::Unit::Common::AttributeMapper

            def self.map
              {
                ews_attributes_examples: :attributes,
              }
            end
          end
        end
      end
    end
  end
end

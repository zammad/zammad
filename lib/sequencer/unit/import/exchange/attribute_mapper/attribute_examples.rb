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

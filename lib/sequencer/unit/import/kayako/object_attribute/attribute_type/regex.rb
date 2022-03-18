# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module ObjectAttribute
          module AttributeType
            class Regex < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Text
              private

              def data_type_specific_options
                super.merge(
                  regex: attribute['regular_expression'],
                )
              end
            end
          end
        end
      end
    end
  end
end

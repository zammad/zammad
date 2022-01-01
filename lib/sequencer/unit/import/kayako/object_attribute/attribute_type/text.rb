# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module ObjectAttribute
          module AttributeType
            class Text < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
              private

              def data_type
                'input'
              end

              def data_type_specific_options
                {
                  type:      'text',
                  maxlength: 255,
                }
              end
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Text < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

              def init_callback(_object_attribte)
                @data_option.merge!(
                  type:      'text',
                  maxlength: 255,
                )
              end

              private

              def data_type(_attribute)
                'input'
              end
            end
          end
        end
      end
    end
  end
end

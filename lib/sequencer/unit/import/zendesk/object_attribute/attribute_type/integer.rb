# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Integer < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

              def init_callback(_object_attribte)
                @data_option.merge!(
                  min: 0,
                  max: 999_999_999,
                )
              end

              private

              def data_type(_attribute)
                'integer'
              end
            end
          end
        end
      end
    end
  end
end

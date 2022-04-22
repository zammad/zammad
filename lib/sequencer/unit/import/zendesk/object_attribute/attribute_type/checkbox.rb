# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Checkbox < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base
              def init_callback(_object_attribte)
                @data_option.merge!(
                  default: false,
                  options: {
                    true  => 'yes',
                    false => 'no',
                  },
                )
              end

              private

              def data_type(_attribute)
                'boolean'
              end
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Regexp < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

              def init_callback(object_attribte)
                @data_option.merge!(
                  type:      'text',
                  maxlength: 255,
                  regex:     object_attribte.regexp_for_validation,
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

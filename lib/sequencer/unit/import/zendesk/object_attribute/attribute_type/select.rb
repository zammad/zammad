# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module ObjectAttribute
          module AttributeType
            class Select < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

              def init_callback(object_attribte)
                @data_option.merge!(
                  default: '',
                  options: options(object_attribte),
                )
              end

              private

              def data_type(_attribute)
                'select'
              end

              def options(object_attribte)
                result = {}
                object_attribte.custom_field_options.each do |entry|
                  result[ entry['value'] ] = entry['name']
                end
                result
              end
            end
          end
        end
      end
    end
  end
end

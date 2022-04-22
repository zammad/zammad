# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module ObjectAttribute
          module AttributeType
            class Checkbox < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Select
              def local_value(value)
                multiple_values = value.split(',').map(&:to_i)

                relevant_options = attribute['options'].select { |option| multiple_values.include?(option['id']) }
                value_locales = relevant_options.filter_map { |option| option['values'].detect { |locale_item| locale_item['locale'] == default_language } }

                value_locales.map { |value_locale| value_locale['translation'] }
              end

              private

              def data_type
                'multiselect'
              end
            end
          end
        end
      end
    end
  end
end

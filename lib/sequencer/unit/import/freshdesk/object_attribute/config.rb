# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module ObjectAttribute
          class Config < Sequencer::Unit::Base
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_any_action

            uses :resource, :sanitized_name, :model_class
            provides :config

            def process
              state.provide(:config) do
                {
                  object:        model_class.to_s,
                  name:          sanitized_name,
                  display:       resource['label'],
                  data_type:     data_type,
                  data_option:   data_option,
                  editable:      true,
                  active:        true,
                  screens:       screens,
                  position:      resource['position'],
                  created_by_id: 1,
                  updated_by_id: 1,
                }
              end
            end

            private

            DATA_TYPE_MAP = {
              'custom_date'      => 'date',
              'custom_checkbox'  => 'boolean',
              'custom_dropdown'  => 'select',
              'custom_text'      => 'input',
              'custom_number'    => 'integer',
              'custom_paragraph' => 'input',
              'custom_decimal'   => 'input',  # Don't use 'integer' as it would cut off the fractional part.
            }.freeze

            def data_type
              @data_type ||= DATA_TYPE_MAP[resource['type']]
            end

            def data_option
              {
                null: true,
                note: '',
              }.merge(data_type_options)
            end

            def data_type_options

              case data_type
              when 'date'
                {
                  future: true,
                  past:   true,
                  diff:   0,
                }
              when 'boolean'
                {
                  default: false,
                  options: {
                    true  => 'yes',
                    false => 'no',
                  },
                }
              when 'select'
                {
                  default: '',
                  options: options,
                }
              when 'input'
                {
                  type:      'text',
                  maxlength: 255,
                }
              when 'integer'
                {
                  min: 0,
                  max: 999_999_999,
                }
              else
                {}
              end
            end

            def screens
              {
                view: {
                  '-all-' => {
                    shown: true,
                    null:  true,
                  },
                  Customer: {
                    shown: false,
                    null:  true,
                  },
                },
                edit: {
                  '-all-' => {
                    shown: true,
                    null:  true,
                  },
                  Customer: {
                    shown: false,
                    null:  true,
                  },
                }
              }
            end

            def options
              resource['choices'].each_with_object({}) do |choice, result|
                result[choice] = choice
              end
            end
          end
        end
      end
    end
  end
end

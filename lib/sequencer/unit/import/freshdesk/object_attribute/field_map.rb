# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module ObjectAttribute
          class FieldMap < Sequencer::Unit::Base
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_any_action

            optional :action

            uses :field_map, :model_class, :resource, :sanitized_name

            def process
              field_map[model_class.name] ||= {}
              field_map[model_class.name][ resource['name'] ] = sanitized_name
            end
          end
        end
      end
    end
  end
end

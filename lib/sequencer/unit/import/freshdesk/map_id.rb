# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class MapId < Sequencer::Unit::Base
          prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

          optional :action

          skip_action :skipped, :failed

          uses :id_map, :model_class, :resource, :instance

          def process
            id_map[model_class.name] ||= {}
            id_map[model_class.name][resource['id']] = instance.id
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class ObjectCount < Sequencer::Unit::Common::Provider::Attribute
          include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

          uses :model_class, :resources

          private

          def statistics_diff
            {
              model_key => empty_diff.merge!(
                total: resources.count
              )
            }
          end

          def model_key
            model_class.name.pluralize.to_sym
          end
        end
      end
    end
  end
end

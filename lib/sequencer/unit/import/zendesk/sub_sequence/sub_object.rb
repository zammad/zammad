# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module SubSequence
          class SubObject < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Zendesk::SubSequence::Base

            uses :resource, :instance, :user_id, :model_class, :action, :field_map

            def self.inherited(subclass)
              super

              subclass.prepend(::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action)
              subclass.skip_action(:skipped, :failed)
            end

            def process
              resource_iteration do |sub_resource|

                ::Sequencer.process(sequence_name,
                                    parameters: default_params.merge(
                                      resource: sub_resource
                                    ),)
              end
            end

            private

            def collection_provider
              resource
            end

            def default_params
              super.merge(
                instance:    instance,
                user_id:     user_id,
                model_class: model_class,
                field_map:   field_map,
              )
            end
          end
        end
      end
    end
  end
end

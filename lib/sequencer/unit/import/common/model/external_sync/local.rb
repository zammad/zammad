require 'sequencer/unit/import/common/model/mixin/handle_failure'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module ExternalSync
            class Local < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnSkippedInstance

              uses :mapped, :remote_id, :model_class, :external_sync_source, :instance_action
              provides :instance

              def process
                return if state.provided?(:instance)

                return if value.blank?
                return if instance.blank?

                create_external_sync

                state.provide(:instance, instance)
              end

              private

              def attribute
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end

              def value
                mapped[attribute]
              end

              def instance
                @instance ||= begin
                  model_class.where(attribute => value).find do |local|
                    !ExternalSync.exists?(
                      source: external_sync_source,
                      object: model_class.name,
                      o_id:   local.id
                    )
                  end
                end
              end

              def create_external_sync
                ExternalSync.create(
                  source:    external_sync_source,
                  source_id: remote_id,
                  object:    import_class.name,
                  o_id:      instance.id
                )
              end
            end
          end
        end
      end
    end
  end
end

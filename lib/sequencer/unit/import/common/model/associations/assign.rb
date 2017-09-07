require 'sequencer/unit/import/common/model/mixin/handle_failure'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Associations
            class Assign < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

              uses :instance, :associations, :instance_action, :dry_run
              provides :instance_action

              def process
                return if dry_run
                return if instance.blank?

                instance.assign_attributes(associations)

                # execute associations check only if needed for performance reasons
                return if instance_action != :unchanged
                return if !changed?
                state.provide(:instance_action, :changed)
              rescue => e
                handle_failure(e)
              end

              private

              def changed?
                logger.debug("Changed instance associations: #{changes.inspect}")
                changes.present?
              end

              def changes
                @changes ||= begin
                  return {} if associations.blank?
                  associations.collect do |association, value|
                    before = compareable(instance.send(association))
                    after  = compareable(value)
                    next if before == after
                    [association, [before, after]]
                  end.compact.to_h.with_indifferent_access
                end
              end

              def compareable(value)
                return nil if value.blank?
                return value.sort if value.respond_to(:sort)
                value
              end
            end
          end
        end
      end
    end
  end
end

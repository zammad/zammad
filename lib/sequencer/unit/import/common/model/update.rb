# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class Update < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_any_action

            uses :instance, :mapped
            provides :action

            def process
              # check if no instance is given - so we can't update it
              return if !instance

              # lock the current instance for write access
              instance.with_lock do
                # delete since we have an update and
                # the record is already created
                mapped.delete(:created_by_id)

                # assign regular attributes
                instance.assign_attributes(mapped)

                action = changed? ? :updated : :unchanged
                state.provide(:action, action)
              end
            rescue => e
              handle_failure(e)
            end

            private

            def changed?
              logger.debug { "Changed instance attributes: #{changes.inspect}" }
              changes.present?
            end

            def changes
              @changes ||= begin
                if instance.has_changes_to_save?
                  # dry run
                  instance.changes_to_save
                else
                  # live run
                  instance.previous_changes
                end
              end
            end
          end
        end
      end
    end
  end
end

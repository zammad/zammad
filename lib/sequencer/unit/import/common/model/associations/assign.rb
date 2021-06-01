# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/model/mixin/handle_failure'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Associations
            class Assign < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

              uses :instance, :associations, :action, :dry_run
              provides :action

              def process
                return if dry_run
                return if instance.blank?
                return if associations.blank? && log_associations_error

                register_changes
                instance.assign_attributes(associations)
              rescue => e
                handle_failure(e)
              end

              private

              # always returns true
              def log_associations_error
                return true if %i[skipped failed deactivated].include?(action)

                logger.error { 'associations cannot be nil' } if associations.nil?
                true
              end

              def register_changes
                return if !(action == :unchanged && changes.any?)

                logger.debug { "Changed instance associations: #{changes.inspect}" }
                state.provide(:action, :updated)
              end

              # Why not just use instance.changes?
              # Because it doesn't include associations
              # stored on OTHER TABLES (has-one, has-many, HABTM)
              def changes
                @changes ||= unfiltered_changes.reject { |_attribute, values| no_diff?(values) }
              end

              def unfiltered_changes
                attrs  = associations.keys
                before = attrs.map { |attribute| instance.send(attribute) }
                after  = associations.values
                attrs.zip(before.zip(after)).to_h.with_indifferent_access
              end

              def no_diff?(values)
                values.map!(&:sort) if values.all? { |val| val.respond_to?(:sort) }
                values.map!(&:presence) # [nil, []] -> [nil, nil]
                values.uniq.length == 1
              end
            end
          end
        end
      end
    end
  end
end

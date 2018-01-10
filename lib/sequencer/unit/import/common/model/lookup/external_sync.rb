class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Lookup
            class ExternalSync < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_action :skipped

              uses :remote_id, :model_class, :external_sync_source
              provides :instance

              def process
                return if !synced_instance

                state.provide(:instance) do
                  model_class.find(synced_instance.o_id)
                end
              rescue => e
                handle_failure(e)
              end

              private

              def synced_instance
                @synced_instance ||= correct_entry || corrected_entry
              end

              def correct_entry
                ::ExternalSync.find_by(
                  source:    external_sync_source,
                  source_id: sanitized_remote_id,
                  object:    model_class.name,
                )
              end

              def sanitized_remote_id
                @sanitized_remote_id ||= ::ExternalSync.sanitized_source_id(remote_id)
              end

              def corrected_entry
                return if obsolete_entry.blank?
                obsolete_entry.update!(source_id: sanitized_remote_id)
                obsolete_entry
              end

              def obsolete_entry
                @obsolete_entry ||= begin
                  if Rails.application.config.db_case_sensitive
                    case_sensitive_entry
                  else
                    case_insensitive_entry
                  end
                end
              end

              def case_sensitive_entry
                ::ExternalSync.where(
                  source: external_sync_source,
                  object: model_class.name,
                ).where('LOWER(source_id) = LOWER(?)', remote_id).first
              end

              def case_insensitive_entry
                ::ExternalSync.find_by(
                  source:    external_sync_source,
                  source_id: remote_id,
                  object:    model_class.name,
                )
              end
            end
          end
        end
      end
    end
  end
end

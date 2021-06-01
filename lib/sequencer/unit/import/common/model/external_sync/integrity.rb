# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module ExternalSync
            class Integrity < Sequencer::Unit::Base
              uses :instance, :remote_id, :dry_run, :external_sync_source, :model_class

              def process
                return if dry_run
                return if instance.blank?
                return if instance.id.blank?
                return if up_to_date?

                create
              end

              private

              def up_to_date?
                return false if entry.blank?
                return true if entry.source_id == remote_id

                entry.update!(source_id: remote_id)
                true
              end

              def entry
                @entry ||= begin
                  ::ExternalSync.find_by(
                    source: external_sync_source,
                    object: model_class.name,
                    o_id:   instance.id
                  )
                end
              end

              def create
                ::ExternalSync.create(
                  source:    external_sync_source,
                  source_id: remote_id,
                  object:    model_class.name,
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

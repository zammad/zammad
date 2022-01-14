# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          module Mapping
            class FromConfig < Sequencer::Unit::Import::Common::Mapping::FlatKeys

              uses :import_job

              private

              def mapping
                from_import_job || ::Import::Exchange.config[:attributes]
              end

              def from_import_job
                return if !state.provided?(:import_job)

                payload = import_job.payload
                return if payload.blank?

                payload[:ews_attributes]
              end
            end
          end
        end
      end
    end
  end
end

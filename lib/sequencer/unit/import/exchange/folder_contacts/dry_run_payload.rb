class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class DryRunPayload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToState

            provides :ews_config, :ews_folder_ids
          end
        end
      end
    end
  end
end

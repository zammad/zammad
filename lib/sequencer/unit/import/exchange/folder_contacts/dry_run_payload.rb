# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class DryRunPayload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute

            provides :ews_config, :ews_folder_ids
          end
        end
      end
    end
  end
end

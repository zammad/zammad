# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          class ExternalSyncSource < Sequencer::Unit::Common::Provider::Named

            def external_sync_source
              'Exchange::FolderContact'
            end
          end
        end
      end
    end
  end
end

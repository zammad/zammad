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

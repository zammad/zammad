class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class FolderIds < Sequencer::Unit::Common::FallbackProvider

            provides :ews_folder_ids

            private

            def fallback
              ::Import::Exchange.config[:folders]
            end
          end
        end
      end
    end
  end
end

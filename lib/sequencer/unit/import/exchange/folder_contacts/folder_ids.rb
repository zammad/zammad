# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class FolderIds < Sequencer::Unit::Common::Provider::Fallback

            provides :ews_folder_ids

            private

            def ews_folder_ids
              ::Import::Exchange.config[:folders]
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

require 'sequencer/mixin/exchange/folder'

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class FolderIds < Sequencer::Unit::Base
            include ::Sequencer::Mixin::Exchange::Folder

            provides :ews_folder_ids

            def process
              # check if ids are already processed
              return if state.provided?(:ews_folder_ids)

              state.provide(:ews_folder_ids) do
                config = ::Import::Exchange.config
                config[:folders]
              end
            end
          end
        end
      end
    end
  end
end

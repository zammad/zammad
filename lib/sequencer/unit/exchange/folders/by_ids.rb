# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Exchange
      module Folders
        class ByIds < Sequencer::Unit::Base
          include ::Sequencer::Unit::Exchange::Folders::Mixin::Folder

          uses :ews_folder_ids
          provides :ews_folders

          def process
            state.provide(:ews_folders) do
              ews_folder_ids.collect do |folder_id|
                ews_folder.find(folder_id)
              end
            end
          end
        end
      end
    end
  end
end

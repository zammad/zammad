# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Exchange
      module Folders
        class IdPathMap < Sequencer::Unit::Base
          include ::Sequencer::Unit::Exchange::Folders::Mixin::Folder

          optional :ews_folder_ids
          provides :ews_folder_id_path_map

          def process
            state.provide(:ews_folder_id_path_map) do

              ids   = ews_folder_ids
              ids ||= []

              ews_folder.id_folder_map.collect do |id, folder|
                next if ids.present? && ids.exclude?(id)
                next if folder.total_count.blank?
                next if folder.total_count.zero?

                [id, ews_folder.display_path(folder)]
              end.compact.to_h
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Exchange::Folders::IdPathMap < Sequencer::Unit::Base
  include ::Sequencer::Unit::Exchange::Folders::Mixin::Folder

  optional :ews_folder_ids
  provides :ews_folder_id_path_map

  def process
    state.provide(:ews_folder_id_path_map) do

      ids   = ews_folder_ids
      ids ||= []

      ews_folder.id_folder_map.filter_map do |id, folder|
        next if ids.present? && ids.exclude?(id)
        next if folder.total_count.blank?
        next if folder.total_count.zero?

        [id, ews_folder.display_path(folder)]
      end.to_h
    end
  end
end

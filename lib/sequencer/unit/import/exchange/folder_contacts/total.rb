# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContacts::Total < Sequencer::Unit::Base
  include ::Sequencer::Unit::Exchange::Folders::Mixin::Folder
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Common

  uses :ews_folder_ids
  provides :statistics_diff

  def process
    state.provide(:statistics_diff, diff)
  end

  private

  def diff
    result = empty_diff.merge(
      folders: {},
    )

    folder_total_map.each do |display_path, total|

      result[:folders][display_path] = empty_diff.merge(
        total: total
      )

      result[:total] += total
    end
    result
  end

  def folder_total_map
    ews_folder_ids.to_h do |folder_id|
      folder       = ews_folder.find(folder_id)
      display_path = ews_folder.display_path(folder)

      [display_path, folder.total_count]
    end
  end
end

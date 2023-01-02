# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::AttributeMapper::AvailableFolders < Sequencer::Unit::Common::AttributeMapper

  def self.map
    {
      ews_folder_id_path_map: :folders,
    }
  end
end

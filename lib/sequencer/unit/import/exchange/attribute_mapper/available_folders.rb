# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module AttributeMapper
          class AvailableFolders < Sequencer::Unit::Common::AttributeMapper

            def self.map
              {
                ews_folder_id_path_map: :folders,
              }
            end
          end
        end
      end
    end
  end
end

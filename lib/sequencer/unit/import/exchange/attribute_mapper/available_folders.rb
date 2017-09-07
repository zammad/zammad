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

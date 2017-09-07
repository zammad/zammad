require 'sequencer/mixin/exchange/folder'

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class Sum < Sequencer::Unit::Base
            include ::Sequencer::Mixin::Exchange::Folder

            uses :ews_folder_ids
            provides :statistics_diff

            def process
              state.provide(:statistics_diff, diff)
            end

            private

            def diff
              result = {
                sum: 0,
              }
              folder_sum_map.each do |display_path, sum|

                result[display_path] = {
                  sum: sum
                }

                result[:sum] += sum
              end
              result
            end

            def folder_sum_map
              ews_folder_ids.collect do |folder_id|
                folder       = ews_folder.find(folder_id)
                display_path = ews_folder.display_path(folder)

                [display_path, folder.total_count]
              end.to_h
            end
          end
        end
      end
    end
  end
end

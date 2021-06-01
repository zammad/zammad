# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class Total < Sequencer::Unit::Base
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

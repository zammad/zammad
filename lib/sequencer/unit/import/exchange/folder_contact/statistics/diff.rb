# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          module Statistics
            class Diff < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

              uses :ews_folder_name

              def process
                state.provide(:statistics_diff) do
                  # build structure for a general diff
                  # and a folder specific sub structure
                  diff.merge(
                    folders: {
                      ews_folder_name => diff
                    }
                  )
                end
              end

              private

              def actions
                %i[created updated unchanged skipped failed]
              end
            end
          end
        end
      end
    end
  end
end

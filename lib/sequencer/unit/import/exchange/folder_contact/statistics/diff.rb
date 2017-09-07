class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          module Statistics
            class Diff < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Diff

              uses :ews_folder_name

              def process
                state.provide(:statistics_diff) do
                  # remove :sum since it's already set via
                  # the exchange item attribte
                  result = diff.except(:sum)

                  # build structure for a general diff
                  # and a folder specific sub structure
                  result.merge(
                    folders: {
                      ews_folder_name => result
                    }
                  )
                end
              end

              private

              def actions
                %i(created updated unchanged skipped failed)
              end
            end
          end
        end
      end
    end
  end
end

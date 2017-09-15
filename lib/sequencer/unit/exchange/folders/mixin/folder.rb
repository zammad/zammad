class Sequencer
  class Unit
    module Exchange
      module Folders
        module Mixin
          module Folder

            def self.included(base)
              base.uses :ews_connection
            end

            private

            def ews_folder
              @ews_folder ||= ::Import::Exchange::Folder.new(ews_connection)
            end
          end
        end
      end
    end
  end
end

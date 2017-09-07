class Sequencer
  module Mixin
    module Exchange
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

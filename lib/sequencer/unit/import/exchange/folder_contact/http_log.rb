# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          class HttpLog < Import::Common::Model::HttpLog

            private

            def facility
              'EWS'
            end
          end
        end
      end
    end
  end
end

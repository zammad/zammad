# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          class RemoteId < Sequencer::Unit::Import::Common::Model::Attributes::RemoteId
            private

            def attribute
              :item_id
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          module Mapping
            class Login < Sequencer::Unit::Import::Common::Mapping::FlatKeys
              include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

              uses :remote_id

              def process
                provide_mapped do
                  {
                    login: remote_id
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end

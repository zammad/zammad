class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContact
          class StaticAttributes < Sequencer::Unit::Base

            provides :model_class, :external_sync_source

            def process
              state.provide(:model_class, ::User)
              state.provide(:external_sync_source, 'Exchange::FolderContact')
            end
          end
        end
      end
    end
  end
end

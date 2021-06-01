# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Attributes
            class RemoteId < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

              uses :resource
              provides :remote_id

              def process
                state.provide(:remote_id) do
                  resource.fetch(attribute).dup.to_s
                end
              rescue KeyError => e
                handle_failure(e)
              end

              private

              def attribute
                :id
              end
            end
          end
        end
      end
    end
  end
end

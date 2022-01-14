# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Skip
            module Blank
              class Resource < Sequencer::Unit::Import::Common::Model::Skip::Blank::Base
                uses :resource
              end
            end
          end
        end
      end
    end
  end
end

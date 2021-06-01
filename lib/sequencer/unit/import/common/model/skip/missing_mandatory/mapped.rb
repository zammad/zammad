# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Skip
            module MissingMandatory
              class Mapped < Sequencer::Unit::Import::Common::Model::Skip::MissingMandatory::Base
                uses :mapped
              end
            end
          end
        end
      end
    end
  end
end

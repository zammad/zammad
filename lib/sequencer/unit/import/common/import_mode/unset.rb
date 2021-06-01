# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module ImportMode
          class Unset < Sequencer::Unit::Base

            def process
              Setting.set('import_mode', false)
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module ImportMode
          class Check < Sequencer::Unit::Base

            def process
              # check if system is in import mode
              return if Setting.get('import_mode')

              raise 'System is not in import mode!'
            end
          end
        end
      end
    end
  end
end

class Sequencer
  class Unit
    module Import
      module Common
        module SystemInitDone
          class Check < Sequencer::Unit::Base

            def process
              return if !Setting.get('system_init_done')

              raise 'System is already system_init_done!'
            end
          end
        end
      end
    end
  end
end

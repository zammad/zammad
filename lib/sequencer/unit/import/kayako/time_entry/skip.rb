# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module TimeEntry
          class Skip < Sequencer::Unit::Base
            uses :resource
            provides :action

            def process
              return if resource['log_type'] != 'VIEWED'

              state.provide(:action, :skipped)
            end
          end
        end
      end
    end
  end
end

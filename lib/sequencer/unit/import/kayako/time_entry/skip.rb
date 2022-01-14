# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

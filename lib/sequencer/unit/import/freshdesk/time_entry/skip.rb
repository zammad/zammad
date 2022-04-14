# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module TimeEntry
          class Skip < Sequencer::Unit::Base
            uses :time_entry_available
            provides :action

            def process
              return if time_entry_available

              state.provide(:action, :skipped)
            end
          end
        end
      end
    end
  end
end

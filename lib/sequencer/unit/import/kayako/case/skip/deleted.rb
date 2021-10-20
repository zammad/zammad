# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          module Skip
            class Deleted < Sequencer::Unit::Base

              uses :resource
              provides :action

              def process
                return if resource['state'] != 'TRASH'

                logger.info { "Skipping. Kayako Case ID '#{resource['id']}' is in 'TRASH' state." }
                state.provide(:action, :skipped)
              end
            end
          end
        end
      end
    end
  end
end

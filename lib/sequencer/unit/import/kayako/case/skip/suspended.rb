# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          module Skip
            class Suspended < Sequencer::Unit::Base

              uses :resource
              provides :action

              def process
                return if resource['state'] != 'SUSPENDED'

                logger.info { "Skipping. Kayako Case ID '#{resource['id']}' is in 'SUSPENDED' state." }
                state.provide(:action, :skipped)
              end
            end
          end
        end
      end
    end
  end
end

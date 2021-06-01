# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module HandleFailure

              def self.included(base)
                base.provides :exception, :action
              end

              def handle_failure(e)
                logger.error(e)
                state.provide(:exception, e)
                state.provide(:action, :failed)
              end
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class UserId < Sequencer::Unit::Base

              uses :resource, :user_map
              provides :user_id

              def process
                state.provide(:user_id) do
                  user_map.fetch(resource.author_id, 1)
                end
              end
            end
          end
        end
      end
    end
  end
end

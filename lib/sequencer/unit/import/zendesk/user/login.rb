# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class Login < Sequencer::Unit::Common::Provider::Named

            uses :resource

            private

            def login
              # Zendesk users may have no other identifier than the ID, e.g. twitter users
              resource.email || resource.id.to_s
            end
          end
        end
      end
    end
  end
end

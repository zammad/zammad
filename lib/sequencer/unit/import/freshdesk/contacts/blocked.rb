# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Contacts
          class Blocked < Sequencer::Unit::Import::Freshdesk::Contacts::Default

            def request_params
              super.merge(
                state: 'blocked',
              )
            end

          end
        end
      end
    end
  end
end

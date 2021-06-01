# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Contacts
          class Deleted < Sequencer::Unit::Import::Freshdesk::Contacts::Default

            def request_params
              super.merge(
                state: 'deleted',
              )
            end

          end
        end
      end
    end
  end
end

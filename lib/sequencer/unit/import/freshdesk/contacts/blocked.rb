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

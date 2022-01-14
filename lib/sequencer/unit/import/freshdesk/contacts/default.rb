# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Contacts
          class Default < Sequencer::Unit::Import::Freshdesk::SubSequence::Object

            def object
              'Contact'
            end
          end
        end
      end
    end
  end
end

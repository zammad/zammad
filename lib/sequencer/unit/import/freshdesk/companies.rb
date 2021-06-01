# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Companies < Sequencer::Unit::Import::Freshdesk::SubSequence::Object
        end
      end
    end
  end
end

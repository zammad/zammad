# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        class UserFields < Sequencer::Unit::Import::Zendesk::SubSequence::ObjectFields
        end
      end
    end
  end
end

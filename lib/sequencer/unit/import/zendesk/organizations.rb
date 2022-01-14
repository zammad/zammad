# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        class Organizations < Sequencer::Unit::Import::Zendesk::SubSequence::Object
          include ::Sequencer::Unit::Import::Zendesk::Mixin::IncrementalExport
        end
      end
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Organizations < Sequencer::Unit::Import::Zendesk::SubSequence::Object
  include ::Sequencer::Unit::Import::Zendesk::Mixin::IncrementalExport
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Organizations < Sequencer::Unit::Import::Zendesk::SubSequence::Object
  include ::Sequencer::Unit::Import::Zendesk::Mixin::IncrementalExport
end

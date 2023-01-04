# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Contacts::Default < Sequencer::Unit::Import::Freshdesk::SubSequence::Object

  def object
    'Contact'
  end
end

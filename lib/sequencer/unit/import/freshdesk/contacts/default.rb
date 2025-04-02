# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Contacts::Default < Sequencer::Unit::Import::Freshdesk::SubSequence::Object
  uses :skip_initial_contacts

  def object
    'Contact'
  end

  def process
    return if skip_initial_contacts

    super
  end
end

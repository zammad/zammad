# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::From < Sequencer::Unit::Import::Zendesk::Ticket::Comment::SourceBased

  private

  def email
    resource.via.source.from.address
  end

  def facebook
    resource.via.source.from.facebook_id
  end
end

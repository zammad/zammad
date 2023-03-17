# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::To < Sequencer::Unit::Import::Zendesk::Ticket::Comment::SourceBased

  private

  def email
    # Notice resource.via.from.original_recipients = [\"another@gmail.com\", \"support@example.zendesk.com\"]
    resource.via.source.to.address
  end

  def facebook
    resource.via.source.to.facebook_id
  end
end

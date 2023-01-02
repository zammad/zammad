# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :instance, :resource, :user_id, :from, :to, :article_sender_id, :article_type_id
  provides :mapped

  def process
    provide_mapped do
      {
        from:          from,
        to:            to,
        ticket_id:     instance.id,
        body:          resource.html_body,
        content_type:  'text/html',
        internal:      !resource.public,
        message_id:    resource.id,
        updated_by_id: user_id,
        created_by_id: user_id,
        updated_at:    resource.created_at,
        created_at:    resource.created_at,
        sender_id:     article_sender_id,
        type_id:       article_type_id,
      }
    end
  end
end

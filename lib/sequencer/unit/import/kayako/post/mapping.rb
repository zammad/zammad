# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :instance, :resource, :created_by_id, :article_sender_id, :article_source_channel
  provides :mapped

  def process
    provide_mapped do
      {
        ticket_id:     instance.id,
        sender_id:     article_sender_id,
        created_by_id: created_by_id,
        updated_by_id: created_by_id,
      }.merge(article_source_channel.mapping)
    end
  end
end

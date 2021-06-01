# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class Mapping < Sequencer::Unit::Base
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
                    sender_id:     article_sender_id,
                    type_id:       article_type_id,
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end

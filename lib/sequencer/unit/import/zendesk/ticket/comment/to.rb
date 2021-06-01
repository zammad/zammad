# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class To < Sequencer::Unit::Import::Zendesk::Ticket::Comment::SourceBased

              private

              def email
                # Notice resource.via.from.original_recipients = [\"another@gmail.com\", \"support@example.zendesk.com\"]
                resource.via.source.to.address
              end

              def facebook
                resource.via.source.to.facebook_id
              end
            end
          end
        end
      end
    end
  end
end

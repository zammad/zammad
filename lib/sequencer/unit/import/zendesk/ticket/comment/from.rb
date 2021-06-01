# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class From < Sequencer::Unit::Import::Zendesk::Ticket::Comment::SourceBased

              private

              def email
                resource.via.source.from.address
              end

              def facebook
                resource.via.source.from.facebook_id
              end
            end
          end
        end
      end
    end
  end
end

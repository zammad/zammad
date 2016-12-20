module Import
  module Zendesk
    class Ticket
      module CommentFactory
        extend Import::Zendesk::Ticket::SubObjectFactory
      end
    end
  end
end

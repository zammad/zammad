module Import
  module Zendesk
    class Ticket
      class Comment
        module AttachmentFactory
          # we need to loop over each instead of all!
          # so we can use the default import factory here
          extend Import::Factory

          private

          def create_instance(record, *args)
            local_article = args[0]
            backend_class(record).new(record, local_article)
          end
        end
      end
    end
  end
end

module Import
  module Zendesk
    class Ticket
      class Comment
        module AttachmentFactory
          # we need to loop over each instead of all!
          # so we can use the default import factory here
          extend Import::Factory

          # rubocop:disable Style/ModuleFunction
          extend self

          private

          # special handling which only starts import if needed
          # Attention: skip? method can't be used since it (currently)
          # only checks for single records - not all
          def import_loop(records, *args, &import_block)
            local_article     = args[0]
            local_attachments = local_article.attachments

            return if local_attachments.count == records.count
            # get a common ground
            local_attachments.each(&:delete)
            return if records.empty?

            records.each(&import_block)
          end

          def create_instance(record, *args)
            local_article = args[0]
            backend_class(record).new(record, local_article)
          end
        end
      end
    end
  end
end

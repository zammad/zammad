module Import
  module Zendesk
    class Ticket
      class Comment
        class Attachment
          include Import::Helper

          def initialize(attachment, local_article)

            response = request(attachment)
            return if !response

            ::Store.add(
              object:      'Ticket::Article',
              o_id:        local_article.id,
              data:        response.body,
              filename:    attachment.file_name,
              preferences: {
                'Content-Type' => attachment.content_type
              },
              created_by_id: 1
            )
          rescue => e
            log e.message
          end

          private

          def request(attachment)
            response = UserAgent.get(
              attachment.content_url,
              {},
              {
                open_timeout: 10,
                read_timeout: 60,
              },
            )
            return response if response.success?
            log response.error
            nil
          end
        end
      end
    end
  end
end

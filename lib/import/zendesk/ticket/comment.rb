module Import
  module Zendesk
    class Ticket
      class Comment

        def initialize(comment, local_ticket, _zendesk_ticket)
          create_or_update(comment, local_ticket)
          import_attachments(comment)
        end

        private

        def create_or_update(comment, local_ticket)
          mapped_article = local_article_fields(comment, local_ticket)
          return if updated?(mapped_article)
          create(mapped_article)
        end

        def updated?(article)
          @local_article = ::Ticket::Article.find_by(message_id: article[:message_id])
          return false if !@local_article
          @local_article.update_attributes(article)
          true
        end

        def create(article)
          @local_article = ::Ticket::Article.create(article)
        end

        def local_article_fields(comment, local_ticket)

          local_user_id = Import::Zendesk::UserFactory.local_id( comment.author_id ) || 1

          {
            ticket_id:     local_ticket.id,
            body:          comment.html_body,
            content_type:  'text/html',
            internal:      !comment.public,
            message_id:    comment.id,
            updated_by_id: local_user_id,
            created_by_id: local_user_id,
            sender_id:     Import::Zendesk::Ticket::Comment::Sender.local_id( local_user_id ),
            type_id:       Import::Zendesk::Ticket::Comment::Type.local_id(comment),
          }.merge(from_to(comment))
        end

        def from_to(comment)
          if comment.via.channel == 'email'
            {
              from: comment.via.source.from.address,
              to:   comment.via.source.to.address # Notice comment.via.from.original_recipients = [\"another@gmail.com\", \"support@example.zendesk.com\"]
            }
          elsif comment.via.channel == 'facebook'
            {
              from: comment.via.source.from.facebook_id,
              to:   comment.via.source.to.facebook_id
            }
          else
            {}
          end
        end

        def import_attachments(comment)
          attachments = comment.attachments
          return if attachments.empty?
          Import::Zendesk::Ticket::Comment::AttachmentFactory.import(attachments, @local_article)
        end
      end
    end
  end
end

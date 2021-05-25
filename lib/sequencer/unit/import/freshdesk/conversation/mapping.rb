class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Conversation
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource, :id_map

            SOURCE_MAP = {
              0  => ::Ticket::Article::Type.select(:id).find_by(name: 'email').id, # Reply
              1  => ::Ticket::Article::Type.select(:id).find_by(name: 'email').id, # Email
              2  => ::Ticket::Article::Type.select(:id).find_by(name: 'web').id, # Note
              3  => ::Ticket::Article::Type.select(:id).find_by(name: 'phone').id, # Phone
              4  => ::Ticket::Article::Type.select(:id).find_by(name: 'note').id, # UNKNOWN!
              5  => ::Ticket::Article::Type.select(:id).find_by(name: 'twitter status').id, # Created from tweets
              6  => ::Ticket::Article::Type.select(:id).find_by(name: 'web').id, # Created from survey feedback
              7  => ::Ticket::Article::Type.select(:id).find_by(name: 'facebook feed post').id, # Created from Facebook post
              8  => ::Ticket::Article::Type.select(:id).find_by(name: 'email').id, # Created from Forwarded Email
              9  => ::Ticket::Article::Type.select(:id).find_by(name: 'note').id, # Created from Phone
              10 => ::Ticket::Article::Type.select(:id).find_by(name: 'note').id, # Created from Mobihelp
              11 => ::Ticket::Article::Type.select(:id).find_by(name: 'note').id, # E-Commerce
            }.freeze

            INCOMING_MAP = {
              true  => ::Ticket::Article::Sender.select(:id).find_by(name: 'Customer').id,
              false => ::Ticket::Article::Sender.select(:id).find_by(name: 'Agent').id,
            }.freeze

            def process  # rubocop:disable Metrics/AbcSize
              provide_mapped do
                {
                  from:          resource['from_email'],
                  to:            resource['to_emails']&.join(', '),
                  cc:            resource['cc_emails']&.join(', '),
                  ticket_id:     ticket_id,
                  body:          resource['body'],
                  content_type:  'text/html',
                  internal:      resource['private'].present?,
                  message_id:    resource['id'],
                  updated_by_id: user_id,
                  created_by_id: user_id,
                  sender_id:     INCOMING_MAP[ resource['incoming'] ],
                  type_id:       SOURCE_MAP[ resource['source'] ],
                  created_at:    resource['created_at'],
                  updated_at:    resource['updated_at'],
                }
              end
            end

            private

            def ticket_id
              id_map['Ticket'][resource['ticket_id']]
            end

            def user_id
              id_map['User'][resource['user_id']]
            end
          end
        end
      end
    end
  end
end

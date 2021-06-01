# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Description
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource, :id_map

            # Since the imports rely on a fresh Zammad installation, we
            #   can require the default article types to be present.
            def source_map # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
              @source_map ||= {
                0  => ::Ticket::Article::Type.select(:id).find_by(name: 'email')&.id, # Reply
                1  => ::Ticket::Article::Type.select(:id).find_by(name: 'email')&.id, # Email
                2  => ::Ticket::Article::Type.select(:id).find_by(name: 'web')&.id, # Note
                3  => ::Ticket::Article::Type.select(:id).find_by(name: 'phone')&.id, # Phone
                4  => ::Ticket::Article::Type.select(:id).find_by(name: 'note')&.id, # UNKNOWN!
                5  => ::Ticket::Article::Type.select(:id).find_by(name: 'twitter status')&.id, # Created from tweets
                6  => ::Ticket::Article::Type.select(:id).find_by(name: 'web')&.id, # Created from survey feedback
                7  => ::Ticket::Article::Type.select(:id).find_by(name: 'facebook feed post')&.id, # Created from Facebook post
                8  => ::Ticket::Article::Type.select(:id).find_by(name: 'email')&.id, # Created from Forwarded Email
                9  => ::Ticket::Article::Type.select(:id).find_by(name: 'note')&.id, # Created from Phone
                10 => ::Ticket::Article::Type.select(:id).find_by(name: 'note')&.id, # Created from Mobihelp
                11 => ::Ticket::Article::Type.select(:id).find_by(name: 'note')&.id, # E-Commerce
              }.freeze
            end

            def process # rubocop:disable Metrics/AbcSize
              provide_mapped do
                {
                  from:          from,
                  to:            resource['to_emails']&.join(', '),
                  cc:            resource['cc_emails']&.join(', '),
                  ticket_id:     ticket_id,
                  body:          resource['description'],
                  content_type:  'text/html',
                  internal:      false,
                  message_id:    "ticketid#{resource['id']}@freshdesk.com",
                  sender_id:     ::Ticket::Article::Sender.select(:id).find_by(name: 'Customer').id,
                  type_id:       source_map[ resource['source'] ],
                  updated_by_id: requester_id,
                  created_by_id: requester_id,
                  created_at:    resource['created_at'],
                  updated_at:    resource['updated_at'],
                }
              end
            end

            private

            def from
              return nil if resource['to_emails'].blank?

              ::User.find(requester_id).email
            end

            def requester_id
              id_map['User'][resource['requester_id']]
            end

            def ticket_id
              id_map['Ticket'][resource['id']]
            end
          end
        end
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class ArticleInputType < Gql::Types::BaseInputObject
    description 'Represents the article attributes to be used in ticket create/update.'

    argument :body, String, required: false, description: 'The article body.'
    argument :subject, String, required: false, description: 'The article subject.'
    argument :internal, Boolean, required: false, description: 'Whether the article is internal.'
    argument :type, String, required: false, description: 'The article type.'
    argument :sender, String, required: false, description: 'The article sender.'
    argument :from, String, required: false, description: 'The article sender address.'
    argument :to, [String], required: false, description: 'The article recipient address.'
    argument :cc, [String], required: false, description: 'The article CC address.'
    argument :content_type, String, required: false, description: 'The article content type.'
    argument :subtype, String, required: false, description: 'The article subtype.'
    argument :in_reply_to, String, required: false, description: 'Message id of the article this article replies to.'
    argument :time_unit, Float, required: false, description: 'The article accounted time.'
    argument :preferences, GraphQL::Types::JSON, required: false, description: 'The article preferences.'
    argument :attachments, Gql::Types::Input::AttachmentInputType, required: false, description: 'The article attachments.'
    argument :security, [Gql::Types::Enum::SecurityOptionType], required: false, description: 'The article security options.'

    transform :transform_type
    transform :transform_subtype
    transform :transform_sender
    transform :transform_customer_article
    transform :transform_security

    def transform_type(payload)
      payload.to_h.tap do |result|
        result[:type] = Ticket::Article::Type.lookup(name: result[:type].presence || 'note')
      end
    end

    def transform_sender(payload)
      # TODO: not correct, should use "agent_read_access?" check from ticket_policy
      sender_name = context.current_user.permissions?('ticket.agent') ? 'Agent' : 'Customer'
      article_sender = payload[:sender].presence || sender_name

      payload[:sender] = Ticket::Article::Sender.lookup(name: article_sender)

      payload
    end

    def transform_customer_article(payload)
      return payload if context.current_user.permissions?('ticket.agent')

      payload[:sender] = Ticket::Article::Sender.lookup(name: 'Customer')

      if payload[:type].name.match?(%r{^(note|web)$})
        payload[:type] = Ticket::Article::Type.lookup(name: 'note')
      end

      payload[:internal] = false

      payload
    end

    def transform_subtype(payload)
      subtype = payload.delete(:subtype) if payload[:subtype]

      if subtype.present?
        payload[:preferences] ||= {}
        payload[:preferences][:subtype] = subtype
      end

      payload
    end

    def transform_security(payload)
      security = payload.delete(:security) if payload[:security]

      return payload if !Setting.get('smime_integration')

      payload[:preferences] ||= {}
      payload[:preferences]['security'] = {
        'type'       => 'S/MIME',
        'encryption' => {
          'success' => security&.include?('encryption'),
        },
        'sign'       => {
          'success' => security&.include?('sign'),
        },
      }

      payload
    end
  end
end

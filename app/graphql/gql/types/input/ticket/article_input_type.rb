# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class ArticleInputType < Gql::Types::BaseInputObject
    description 'Represents the article attributes to be used in ticket create/update.'

    argument :body, String, required: false, description: 'The article body.'
    argument :subject, String, required: false, description: 'The article subject.', default_value: ''
    argument :internal, Boolean, required: false, description: 'Whether the article is internal.'
    argument :type, String, required: false, description: 'The article type.'
    argument :sender, String, required: false, description: 'The article sender.'
    argument :from, String, required: false, description: 'The article sender address.'
    argument :to, [String], required: false, description: 'The article recipient address.'
    argument :cc, [String], required: false, description: 'The article CC address.'
    argument :content_type, String, required: false, description: 'The article content type.'
    argument :subtype, String, required: false, description: 'The article subtype.'
    argument :in_reply_to, String, required: false, description: 'Message id of the article this article replies to.', default_value: ''
    argument :time_unit, Float, required: false, description: 'The article accounted time.'
    argument :accounted_time_type_id, GraphQL::Types::ID, required: false, loads: Gql::Types::Ticket::TimeAccounting::TypeType, description: 'The article accounted time activity type.'
    argument :preferences, GraphQL::Types::JSON, required: false, description: 'The article preferences.'
    argument :attachments, Gql::Types::Input::AttachmentInputType, required: false, description: 'The article attachments.'
    argument :security, Gql::Types::Input::Ticket::SecurityInputType, required: false, description: 'The article security options.'

    transform :transform_security
    transform :transform_subtype

    def transform_subtype(payload)
      payload = payload.to_h
      subtype = payload.delete(:subtype) if payload[:subtype]

      if subtype.present?
        payload[:preferences] ||= {}
        payload[:preferences][:subtype] = subtype
      end

      payload
    end

    def transform_security(payload)
      payload = payload.to_h

      security = payload.delete(:security)
      return payload if !security_enabled? || security.blank?

      payload[:preferences] ||= {}
      payload[:preferences]['security'] = security_preference(security)

      payload
    end

    private

    def security_enabled?
      Setting.get('smime_integration') || Setting.get('pgp_integration')
    end

    def security_preference(security)
      {
        'type'       => security[:method],
        'encryption' => {
          'success' => security[:options]&.include?('encryption'),
        },
        'sign'       => {
          'success' => security[:options]&.include?('sign'),
        },
      }
    end
  end
end

# https://developer.zendesk.com/rest_api/docs/core/tickets
# https://developer.zendesk.com/rest_api/docs/core/ticket_comments#ticket-comments
# https://developer.zendesk.com/rest_api/docs/core/ticket_audits#the-via-object
# https://developer.zendesk.com/rest_api/docs/help_center/article_attachments
# https://developer.zendesk.com/rest_api/docs/core/ticket_audits # v2
module Import
  module Zendesk
    class Ticket
      include Import::Helper

      def initialize(ticket)
        create_or_update(ticket)
        Import::Zendesk::Ticket::TagFactory.import(ticket.tags, @local_ticket, ticket)
        Import::Zendesk::Ticket::CommentFactory.import(ticket.comments, @local_ticket, ticket)
      end

      private

      def create_or_update(ticket)
        mapped_ticket = local_ticket_fields(ticket)
        return if updated?(mapped_ticket)
        create(mapped_ticket)
      end

      def updated?(ticket)
        @local_ticket = ::Ticket.find_by(id: ticket[:id])
        return false if !@local_ticket
        @local_ticket.update_attributes(ticket)
        true
      end

      def create(ticket)
        @local_ticket = ::Ticket.create(ticket)
        reset_primary_key_sequence('tickets')
      end

      def local_ticket_fields(ticket)
        local_user_id = Import::Zendesk::UserFactory.local_id( ticket.requester_id ) || 1

        {
          id:                       ticket.id,
          title:                    ticket.subject || ticket.description || '-',
          owner_id:                 Import::Zendesk::UserFactory.local_id( ticket.assignee ) || 1,
          note:                     ticket.description,
          group_id:                 Import::Zendesk::GroupFactory.local_id( ticket.group_id ) || 1,
          customer_id:              local_user_id,
          organization_id:          Import::Zendesk::OrganizationFactory.local_id( ticket.organization_id ),
          priority:                 Import::Zendesk::Priority.lookup(ticket),
          state:                    Import::Zendesk::State.lookup(ticket),
          pending_time:             ticket.due_at,
          updated_at:               ticket.updated_at,
          created_at:               ticket.created_at,
          updated_by_id:            local_user_id,
          created_by_id:            local_user_id,
          create_article_sender_id: Import::Zendesk::Ticket::Comment::Sender.local_id(local_user_id),
          create_article_type_id:   Import::Zendesk::Ticket::Comment::Type.local_id(ticket),
        }.merge(custom_fields(ticket))
      end

      def custom_fields(ticket)
        custom_fields = ticket.custom_fields
        fields = {}
        return fields if !custom_fields
        custom_fields.each do |custom_field|
          field_name  = Import::Zendesk::TicketFieldFactory.local_id(custom_field['id'])
          field_value = custom_field['value']
          next if field_value.nil?
          fields[ field_name.to_sym ] = field_value
        end
        fields
      end
    end
  end
end

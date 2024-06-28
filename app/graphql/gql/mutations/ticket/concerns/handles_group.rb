# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations::Ticket::Concerns::HandlesGroup
  extend ActiveSupport::Concern

  included do
    private

    def group_has_email?(input:)
      return true if input[:group].blank?
      return true if input[:article].blank?

      type = input[:article][:type].presence || Setting.get('ui_ticket_create_default_type')
      return true if type.exclude?('email')

      return true if input[:group].email_address.present?

      false
    end

    def group_has_no_email_error
      error_response(
        message: __('This group has no email address configured for outgoing communication.'),
        field:   'group_id'
      )
    end

  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Create < FormUpdater::Updater
  include FormUpdater::Concerns::PreparesTicketSignature
  include FormUpdater::Concerns::AppliesTaskbarState
  include FormUpdater::Concerns::AppliesTicketTemplate
  include FormUpdater::Concerns::AppliesTicketSharedDraft
  include FormUpdater::Concerns::AppliesSplitTicketArticle
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasSecurityOptions
  include FormUpdater::Concerns::ProvidesInitialValues
  include FormUpdater::Concerns::StoresTaskbarState

  core_workflow_screen 'create_middle'

  # The customer a ticket create screen was opened for (and a split article) arrive with the first
  #   round trip and nothing follows them, so without this the tab would be reopened without them.
  store_state_on_initial

  def self.required_permissions
    %w[ticket.agent ticket.customer]
  end

  def object_type
    ::Ticket
  end

  def initial_values
    values = {
      'priority_id' => ::Ticket::Priority.find_by(default_create: true)&.id
    }

    customer_option = FormUpdater::ApplyValue::UserAutocomplete.resolve_option(meta.dig(:additional_data, 'customer_id'), current_user:)
    customer_phone = meta.dig(:additional_data, 'customer_phone')

    if customer_option
      values['customer_id'] = customer_option[:value]

      result['customer_id'] ||= {}
      result['customer_id'][:options] = [customer_option]
    elsif customer_phone.present?
      # A create screen opened for a caller nobody knows yet: the number stands in
      #   for the customer until the ticket is created or a user is picked.
      values['customer_id'] = customer_phone

      result['customer_id'] ||= {}
      result['customer_id'][:options] = [{ value: customer_phone, label: customer_phone }]
    end

    values
  end
end

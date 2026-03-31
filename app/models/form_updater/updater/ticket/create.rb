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

    customer_id = meta.dig(:additional_data, 'customer_id')
    customer_user = ::User.find_by(id: customer_id)

    if customer_user
      # We use the internal_id to avoid coercing the customer_id if it's a string
      values['customer_id'] = customer_user.id

      customer_user_serialized = FormUpdater::Graphql::Serializers::User.serialize(customer_user)

      # For customer_id we need also to add the user as an option.
      # TODO: maybe we can have some generic way for this, because we are also have it in other places (e.g. applies tempalte).
      result['customer_id'] ||= {}
      result['customer_id'][:options] = [{
        value:   customer_user.id,
        label:   customer_user.fullname.presence || customer_user.login,
        heading: customer_user.organization&.name,
        object:  customer_user_serialized
      }]
    end

    values
  end
end

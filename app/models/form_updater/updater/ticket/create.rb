# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Create < FormUpdater::Updater
  include FormUpdater::Concerns::AppliesTaskbarState
  include FormUpdater::Concerns::AppliesTicketTemplate
  include FormUpdater::Concerns::AppliesTicketSharedDraft
  include FormUpdater::Concerns::AppliesSplitTicketArticle
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasSecurityOptions
  include FormUpdater::Concerns::ProvidesInitialValues
  include FormUpdater::Concerns::StoresTaskbarState

  core_workflow_screen 'create_middle'

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
      values['customer_id'] = customer_id

      customer_object = customer_user.attributes
        .slice('active', 'email', 'firstname', 'fullname', 'image', 'lastname', 'mobile', 'out_of_office', 'out_of_office_end_at', 'out_of_office_start_at', 'phone', 'source', 'vip')
        .merge({
                 '__typename' => 'User',
                 'id'         => Gql::ZammadSchema.id_from_internal_id('User', customer_id),
               })

      # For customer_id we need also to add the user as an option.
      # TODO: maybe we can have some generic way for this, because we are also have it in other places (e.g. applies tempalte).
      result['customer_id'] ||= {}
      result['customer_id'][:options] = [{
        value:   customer_id,
        label:   customer_user.fullname.presence || customer_user.phone.presence || customer_user.login,
        heading: customer_user.organization&.name,
        object:  customer_object
      }]
    end

    values
  end
end

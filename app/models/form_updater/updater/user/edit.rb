# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Edit < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'edit'

  def object_type
    ::User
  end

  def resolve
    if meta[:initial] && object && object.organization_ids.present?
      result['organization_ids'] = organization_ids
    end

    super
  end

  private

  def organization_ids
    {
      value:   object.organization_ids,
      options: ::Organization.where(id: object.organization_ids).each_with_object([]) do |organization, options|
                 options << {
                   # TODO: needs to be aligned during the autocomplete query implementation
                   value:        organization.id,
                   label:        organization.name,
                   organization: {
                     active: organization.active,
                   }
                 }
               end,
    }
  end
end

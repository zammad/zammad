# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Invite < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'invite_agent'

  def authorized?
    current_user.permissions?('admin.wizard')
  end

  def object_type
    ::User
  end

  def resolve
    if meta[:initial]
      prepare_initial_data
    end

    super
  end

  private

  def prepare_initial_data
    result['role_ids']  = initial_role_ids
    result['group_ids'] = initial_group_ids
  end

  def initial_role_ids
    {
      options: initial_role_options
    }
  end

  def initial_role_options
    Role
      .where(active: true)
      .reorder(id: :asc)
      .map do |elem|
        {
          value:       elem.id,
          label:       elem.name,
          description: elem.note,
        }
      end
  end

  def initial_group_ids
    {
      options: initial_group_options
    }
  end

  def initial_group_options
    FormUpdater::Relation::Group.new(
      context:,
      current_user:,
      filter_ids:   Group.pluck(:id),
    ).options
  end
end

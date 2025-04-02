# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Notifications < FormUpdater::Updater
  def authorized?
    current_user.permissions?('user_preferences.notifications')
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
    result['group_ids'] = initial_group_ids
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
      filter_ids:   current_user.group_ids
    ).options
  end
end

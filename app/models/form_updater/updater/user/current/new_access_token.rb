# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Current::NewAccessToken < FormUpdater::Updater
  def authorized?
    Setting.get('api_token_access') == true && current_user.permissions?('user_preferences.access_token')
  end

  def resolve
    if meta[:initial]
      result['permissions'] = permissions
    end

    super
  end

  private

  def permissions
    permissions = current_user.permissions_with_child_and_parent_elements

    {
      options: build_options_tree_structure(permissions)
    }
  end

  def build_options_tree_structure(permissions)
    hierarchy = permissions.each_with_object({}) do |permission, memo|
      current_level = memo
      segments = permission.name.split('.')

      segments[...-1].each do |segment|
        current_level[segment] ||= { children: {} }
        current_level = current_level[segment][:children]
      end

      current_level[segments.last] ||= { children: {} }
      current_level[segments.last][:object] = permission
    end

    build_options_array_structure(hierarchy)
  end

  def build_options_array_structure(hierarchy)
    return if hierarchy.blank?

    hierarchy
      .values
      .sort_by do |elem|
        permission = elem[:object]

        [permission.preferences[:prio], permission.name]
      end
      .map do |elem|
        permission = elem[:object]

        {
          value:       permission.name,
          label:       permission.label.presence || permission.name,
          description: permission.description,
          disabled:    permission.preferences[:disabled],
          children:    build_options_array_structure(elem[:children])
        }
      end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    # Filter out permissions which are tied to inactivated settings.
    permissions = permissions.reject do |permission|
      next if permission.preferences[:setting].blank?

      Setting.get(permission.preferences.dig(:setting, :name)) != permission.preferences.dig(:setting, :value)
    end

    {
      options: build_options_tree_structure(permissions + missing_ancestors(permissions))
    }
  end

  # An ancestor the user's permission list leaves out, e.g. the inactive parent of a granted
  #   permission, still has to show for the sake of its children. Like an ancestor the user does
  #   not hold, it cannot be selected itself.
  def missing_ancestors(permissions)
    names          = permissions.map(&:name)
    ancestor_names = names.flat_map { |name| Permission.with_parents(name)[...-1] }.uniq - names

    return [] if ancestor_names.blank?

    Permission.where(name: ancestor_names).each { |permission| permission.preferences['disabled'] = true }
  end

  def build_options_tree_structure(permissions)
    hierarchy = permissions.each_with_object({}) do |permission, memo|
      current_level = memo
      segments = permission.name.split('.')

      segments[...-1].each_with_index do |segment, index|
        current_level[segment] ||= { name: segments[..index].join('.'), children: {} }
        current_level = current_level[segment][:children]
      end

      current_level[segments.last] ||= { name: permission.name, children: {} }
      current_level[segments.last][:object] = permission
    end

    build_options_array_structure(hierarchy)
  end

  def build_options_array_structure(hierarchy)
    return if hierarchy.blank?

    hierarchy
      .values
      .sort_by { |elem| option_sort_key(elem) }
      .map { |elem| build_option(elem) }
  end

  # Permissions created outside of the seeds may carry no priority; they sort after the seeded ones.
  def option_sort_key(elem)
    prio = elem[:object]&.preferences&.dig(:prio)

    [prio.is_a?(Numeric) ? prio : Float::INFINITY, elem[:name]]
  end

  # A node without a permission is an ancestor without a row of its own, e.g. a custom 'a.b.c'
  #   permission lacking 'a.b'. It is shown under its name for its children and cannot be selected.
  def build_option(elem)
    permission = elem[:object]

    {
      value:       elem[:name],
      label:       permission&.label.presence || elem[:name],
      description: permission&.description,
      disabled:    permission ? permission.preferences[:disabled] : true,
      children:    build_options_array_structure(elem[:children])
    }
  end
end

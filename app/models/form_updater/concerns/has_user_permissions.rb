# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::HasUserPermissions
  extend ActiveSupport::Concern

  def resolve
    prepare_initial_data if meta[:initial]

    super
  end

  private

  def prepare_initial_data
    result['role_ids']  = initial_role_ids
    result['group_ids'] = initial_group_ids
  end

  def initial_role_ids
    {
      initialValue: object&.role_ids,
      options:      initial_role_options,
    }.compact
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
      initialValue: initial_group_value,
      options:      initial_group_options,
    }.compact
  end

  def initial_group_value
    # For users without any group permissions, we want to return an empty initial row,
    #   in order to avoid the form flagging the field with a dirty state.
    if object&.saved_group_ids_access_map&.empty?
      return [
        {
          key:         SecureRandom.uuid,
          groups:      [],
          groupAccess: {
            read:     false,
            create:   false,
            overview: false,
            change:   false,
            full:     false,
          },
        }
      ]
    end

    object&.saved_group_ids_access_map&.map do |group_id, group_access|
      {
        key:         SecureRandom.uuid,
        groups:      [group_id],
        groupAccess: group_access.index_with(true),
      }
    end
  end

  def initial_group_options
    FormUpdater::Relation::Group.new(
      context:,
      current_user:,
      filter_ids:   Group.pluck(:id),
    ).options
  end
end

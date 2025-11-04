# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module HasOptionalGroups
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :groups, after_add: :cache_update, after_remove: :cache_update, class_name: 'Group'

    # Finds objects available in given groups
    # Objects with no selected groups as well as having one of the given groups are returned
    scope :available_in_groups, lambda { |groups|
      left_outer_joins(:groups)
        .where(groups: { id: [nil] + Array(groups) })
        .where(active: true)
        .distinct
    }
  end
end

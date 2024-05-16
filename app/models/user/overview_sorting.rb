# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSorting < ApplicationModel
  include HasDefaultModelUserRelations
  include CanPriorization

  belongs_to :user, class_name: 'User'
  belongs_to :overview, inverse_of: :overview_sortings

  default_scope { order(:prio, :id) }
end

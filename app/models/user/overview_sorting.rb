# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSorting < ApplicationModel
  include HasDefaultModelUserRelations

  include CanPriorization

  belongs_to :user, class_name: 'User'
  belongs_to :overview

  default_scope { order(:prio, :id) }

  def self.prio_create(id:, prio:, current_user:)
    overview = Overview.find(id)
    User::OverviewSorting.create!(
      user:       current_user,
      overview:   overview,
      prio:       prio,
      created_by: current_user,
      updated_by: current_user
    )
  end
end

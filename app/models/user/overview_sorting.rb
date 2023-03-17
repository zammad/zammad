# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSorting < ApplicationModel
  include CanPriorization

  belongs_to :user, class_name: 'User'
  belongs_to :overview
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

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

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSortingsController < ApplicationController
  include CanPrioritize

  prepend_before_action { authentication_check && authorize! }

  def index
    render json: {
      overviews:         Ticket::Overviews.all(current_user: current_user),
      overview_sortings: User::OverviewSorting.where(user: current_user),
    }
  end

  def show
    model_show_render(User::OverviewSorting, params)
  end

  def create
    model_create_render(User::OverviewSorting, params)
  end

  def update
    model_update_render(User::OverviewSorting, params)
  end

  def destroy
    model_destroy_render(User::OverviewSorting, params)
  end

  def prio_find(entry_prio)
    klass.find_by(overview_id: entry_prio[0], user: current_user)
  end
end

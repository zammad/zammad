# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSortingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

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
    ActiveRecord::Base.transaction do
      model_destroy_render(User::OverviewSorting, params)
    end

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
        .trigger_by(current_user)
  end

  def prio
    overview_ids = params[:prios].map(&:first)

    authorized_overviews = Ticket::Overviews
      .all(current_user:)
      .where(id: overview_ids)
      .sort_by { |elem| overview_ids.index(elem.id) }

    Service::User::Overview::UpdateOrder
      .new(current_user, authorized_overviews)
      .execute

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
      .trigger_by(current_user)

    render json: { success: true }, status: :ok
  end
end

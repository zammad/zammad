# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSortingsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  before_action :set_user_param, only: %i[create update]

  def index
    render json: {
      overviews:         Ticket::Overviews.all(current_user: current_user, ignore_user_conditions: true),
      overview_sortings: overview_sortings_scope,
    }
  end

  def show
    model_show_render(overview_sortings_scope, params)
  end

  def create
    model_create_render(User::OverviewSorting, params)
  end

  def update
    model_update_render(overview_sortings_scope, params)
  end

  def destroy
    ActiveRecord::Base.transaction do
      model_destroy_render(overview_sortings_scope, params)
    end

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
        .trigger_by(current_user)
  end

  def prio
    overview_ids = params[:prios].map(&:first)

    authorized_overviews = Ticket::Overviews
      .all(current_user:, ignore_user_conditions: true)
      .where(id: overview_ids)
      .sort_by { |elem| overview_ids.index(elem.id) }

    Service::User::Overview::UpdateOrder
      .with_current_user(current_user)
      .execute(authorized_overviews)

    Gql::Subscriptions::User::Current::OverviewOrderingUpdates
      .trigger_by(current_user)

    render json: { success: true }, status: :ok
  end

  private

  def set_user_param
    params[:user_id] = current_user.id
  end

  def overview_sortings_scope
    User::OverviewSorting.where(user: current_user)
  end
end

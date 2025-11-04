# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Analytics::UsagesController < ApplicationController
  prepend_before_action :authentication_check

  def update
    ai_analytics_run = AI::Analytics::Run.find(params[:ai_analytics_run_id])

    authorize! ai_analytics_run, :show?

    Service::AI::Analytics::UpsertUsage
      .new(current_user, ai_analytics_run, **usage_attributes)
      .execute

    render json: { status: :ok }
  end

  private

  def usage_attributes
    @usage_attributes ||= params
      .permit(:rating, :comment, context: {})
      .to_h
      .deep_symbolize_keys
  end
end

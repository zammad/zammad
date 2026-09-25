# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Analytics::UsagesController < ApplicationController
  prepend_before_action :authentication_check

  def update
    ai_analytics_run = AI::Analytics::Run.find(params[:ai_analytics_run_id])

    authorize! ai_analytics_run, :show?

    Service::AI::Analytics::UpsertUsage
      .with_current_user(current_user)
      .execute(ai_analytics_run, **usage_attributes)

    render json: { status: :ok }
  rescue Service::AI::Analytics::UpsertUsage::FeedbackAlreadyProvidedError => e
    # Flagged apart from other unprocessable input, so the client can show the feedback as given.
    render json: { error: e.message, error_human: e.message, feedback_already_provided: true }, status: :unprocessable_content
  end

  private

  def usage_attributes
    @usage_attributes ||= params
      .permit(:rating, :comment, context: {})
      .to_h
      .deep_symbolize_keys
  end
end

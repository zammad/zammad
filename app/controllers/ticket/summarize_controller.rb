# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SummarizeController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def summarize
    Service::CheckFeatureEnabled.execute(name: 'ai_assistance_ticket_summary', custom_exception_class: Exceptions::UnprocessableContent)
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

    authorize!(ticket, :agent_read_access?)
    return render json: { result: nil } if !summary_enabled?

    if regeneration_of
      authorize!(regeneration_of, :show?)
      enqueue_job
      return
    end

    ai_result = Service::Ticket::AIAssistance::Summarize
      .with_current_user(current_user)
      .execute(
        locale:               current_user.locale,
        ticket:,
        persistence_strategy: :stored_only,
      )

    if ai_result&.content.blank?
      # When AI analytics error ID is present, return this error message instead of enqueuing a new job.
      if params[:ai_analytics_run_error_id].present?
        ai_analytics_run_error = AI::Analytics::Run.find(params[:ai_analytics_run_error_id])
        authorize!(ai_analytics_run_error, :show?)

        render json: {
          result:        nil,
          error:         true,
          error_message: ai_analytics_run_error.error['error_message'],
        }
      else
        enqueue_job
      end

      return
    end

    return_stored_result(ai_result)
  end

  private

  def ticket
    @ticket ||= Ticket.find(params[:id])
  end

  def regeneration_of
    return @regeneration_of if defined?(@regeneration_of)

    @regeneration_of = AI::Analytics::Run.find(params[:regeneration_of_id]) if params[:regeneration_of_id].present?
  end

  def enqueue_job
    # Trigger background job to generate summary...
    TicketAIAssistanceSummarizeJob
      .perform_later(ticket, current_user.locale, current_user:, regeneration_of:)

    render json: { result: nil }
  end

  def summary_enabled?
    Service::Ticket::AIAssistance::SummaryEnabled
      .with_current_user(current_user)
      .execute(ticket:)
  end

  def return_stored_result(ai_result)
    usage     = ai_result.ai_analytics_run&.usage_by(current_user)
    is_unread = ticket.ai_summary_unread?(current_user, ai_result.ai_analytics_run)

    render json: {
      result:    ai_result.content,
      analytics: {
        run_id:    ai_result.ai_analytics_run&.id,
        usage:,
        is_unread:
      },
    }
  end
end

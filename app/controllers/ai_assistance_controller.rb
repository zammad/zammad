# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AIAssistanceController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def text_tools
    authorize!(regeneration_of, :show?) if regeneration_of

    text_tool = AI::TextTool.find_by(id: params[:id])

    Rails.logger.error "The text tool with the given ID '#{params[:id]}' could not be found." if text_tool.nil?
    raise Exceptions::UnprocessableEntity, __('The text tool with the given ID could not be found.') if text_tool.nil?

    authorize!(text_tool, :show?)

    output = Service::AIAssistance::TextTools.new(
      input:                   params[:input],
      text_tool:,
      current_user:,
      regeneration_of:,
      template_render_context: template_render_context(params),
    ).execute

    # Implicitly record the analytics usage for the current user.
    Service::AI::Analytics::UpsertUsage
      .new(current_user, output.ai_analytics_run)
      .execute

    render json: {
      output:    output[:content],
      analytics: {
        run_id: output.ai_analytics_run.id,
      },
    }
  end

  private

  def regeneration_of
    return @regeneration_of if defined?(@regeneration_of)

    @regeneration_of = AI::Analytics::Run.find(params[:regeneration_of_id]) if params[:regeneration_of_id].present?
  end

  def template_render_context(params)
    return template_render_context_from_ticket(params[:ticket_id]) if params[:ticket_id].present?

    template_render_context_from_ids(params)
  end

  def template_render_context_from_ticket(ticket_id)
    ticket = Ticket.find_by(id: ticket_id)
    authorize!(ticket, :show?) if ticket

    {
      ticket:       ticket,
      customer:     ticket&.customer,
      group:        ticket&.group,
      organization: ticket&.organization,
    }
  end

  def template_render_context_from_ids(params)
    customer     = User.find_by(id: params[:customer_id])
    group        = Group.find_by(id: params[:group_id])
    organization = Organization.find_by(id: params[:organization_id])

    authorize!(group, :show?) if group

    # It is not needed to check authorization for the customer and organization,
    #   because this endpoint is secured by requiring `ticket.agent` permission.

    {
      # If ticket does not exist yet, fake it with a customer if present.
      ticket:       Ticket.new(customer: customer),
      customer:,
      group:,
      organization:,
    }
  end
end
